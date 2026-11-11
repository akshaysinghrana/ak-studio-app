import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/download_variant.dart';

/// Raised for anything the user should see as a plain message (bad link,
/// server error, encrypted stream, ...).
class DownloadException implements Exception {
  DownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A network-level failure worth retrying (dropped connection, stall, 5xx,
/// rate limiting). The partial file is kept so the retry resumes.
class TransientDownloadException extends DownloadException {
  TransientDownloadException(super.message);
}

/// Raised when the user cancels an in-flight download.
class DownloadCancelled implements Exception {}

/// Raised when the user pauses an in-flight download; partial data is kept.
class DownloadPaused implements Exception {}

/// True for failures that a later attempt can be expected to get past.
bool isTransientDownloadError(Object error) =>
    error is TransientDownloadException ||
    error is SocketException ||
    error is HttpException ||
    error is TlsException ||
    error is TimeoutException;

/// Stop signal shared between the controller and one run of a download.
class DownloadCancelToken {
  var _paused = false;
  var _cancelled = false;
  final _stopped = Completer<void>();

  void cancel() {
    _cancelled = true;
    if (!_stopped.isCompleted) _stopped.complete();
  }

  void pause() {
    if (_cancelled) return;
    _paused = true;
    if (!_stopped.isCompleted) _stopped.complete();
  }

  bool get isCancelled => _cancelled;
  bool get isPaused => _paused && !_cancelled;
  bool get isStopped => _stopped.isCompleted;

  /// Completes as soon as the run is paused or cancelled.
  Future<void> get whenStopped => _stopped.future;

  /// The exception a stopped run ends with.
  Exception get stopError =>
      _cancelled ? DownloadCancelled() : DownloadPaused();

  void throwIfStopped() {
    if (isStopped) throw stopError;
  }
}

/// How far a segmented download got: the number of whole segments written
/// and the bytes they occupy, so a later run continues from there.
class SegmentCursor {
  int segmentsDone = 0;
  int bytesCommitted = 0;

  void reset() {
    segmentsDone = 0;
    bytesCommitted = 0;
  }
}

/// Minimal HTTP client for direct files and segmented streams, built on
/// `dart:io` so the app needs no extra dependency.
class MediaDownloader {
  MediaDownloader({HttpClient? client, this.stallTimeout = defaultStallTimeout})
    : _client = client ?? HttpClient(),
      _ownsClient = client == null {
    _client.connectionTimeout = const Duration(seconds: 30);
  }

  final HttpClient _client;
  final bool _ownsClient;

  static const userAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Mobile Safari/537.36';

  void close() {
    if (_ownsClient) _client.close(force: true);
  }

  /// No bytes for this long means the connection is dead (e.g. it was cut
  /// while the phone switched networks); the run fails as transient and is
  /// retried from where it stopped.
  static const defaultStallTimeout = Duration(seconds: 30);

  final Duration stallTimeout;

  Future<HttpClientResponse> open(
    Uri uri, {
    String? referer,
    int? rangeStart,
  }) async {
    final request = await _client.getUrl(uri).timeout(stallTimeout);
    request.followRedirects = true;
    request.headers.set(HttpHeaders.userAgentHeader, userAgent);
    request.headers.set(HttpHeaders.acceptHeader, '*/*');
    if (referer != null) {
      request.headers.set(HttpHeaders.refererHeader, referer);
    }
    if (rangeStart != null && rangeStart > 0) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$rangeStart-');
    }
    return request.close().timeout(stallTimeout);
  }

  /// Reads up to [maxBytes] of a text resource (HTML pages, manifests).
  Future<String> fetchText(
    Uri uri, {
    int maxBytes = 2 * 1024 * 1024,
    String? referer,
  }) async {
    final response = await open(uri, referer: referer);
    if (response.statusCode >= 400) {
      throw DownloadException('Server returned ${response.statusCode}');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length >= maxBytes) break;
    }
    final end = bytes.length > maxBytes ? maxBytes : bytes.length;
    return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
  }

  /// Sends a URL-encoded form request to a player endpoint and returns its
  /// response text. Some public players expose short-lived stream URLs only
  /// after their own page script makes this request.
  Future<String> postFormText(
    Uri uri,
    Map<String, String> fields, {
    String? referer,
    String? origin,
    Map<String, String> headers = const {},
    int maxBytes = 2 * 1024 * 1024,
  }) async {
    if (uri.scheme != 'https') {
      throw DownloadException('The player endpoint must use HTTPS.');
    }
    final request = await _client.postUrl(uri).timeout(stallTimeout);
    request.followRedirects = true;
    request.headers.set(HttpHeaders.userAgentHeader, userAgent);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/x-www-form-urlencoded;charset=UTF-8',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (referer != null)
      request.headers.set(HttpHeaders.refererHeader, referer);
    if (origin != null) request.headers.set('Origin', origin);
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    request.write(Uri(queryParameters: fields).query);
    final response = await request.close().timeout(stallTimeout);
    if (response.statusCode >= 400) {
      await response.drain<void>();
      throw DownloadException(
        'The player endpoint returned ${response.statusCode}.',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length >= maxBytes) break;
    }
    final end = bytes.length > maxBytes ? maxBytes : bytes.length;
    return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
  }

  /// Content-Length via HEAD, falling back to a ranged GET.
  Future<int?> probeSize(Uri uri, {String? referer}) async {
    try {
      final request = await _client.headUrl(uri);
      request.followRedirects = true;
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      if (referer != null) {
        request.headers.set(HttpHeaders.refererHeader, referer);
      }
      final response = await request.close();
      await response.drain<void>();
      if (response.contentLength > 0) return response.contentLength;
    } on Exception {
      // Fall through to the ranged request.
    }
    try {
      final request = await _client.getUrl(uri);
      request.followRedirects = true;
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      if (referer != null) {
        request.headers.set(HttpHeaders.refererHeader, referer);
      }
      final response = await request.close();
      final range = response.headers.value(HttpHeaders.contentRangeHeader);
      await response.drain<void>();
      if (range != null) {
        final total = int.tryParse(range.split('/').last.trim());
        if (total != null && total > 0) return total;
      }
    } on Exception {
      // Size simply stays unknown.
    }
    return null;
  }

  /// Streams [url] into [destPath] and returns the file's final size. When
  /// [destPath] already holds part of the file (a paused or interrupted run)
  /// the rest is requested with an HTTP Range; servers that ignore ranges
  /// send the whole file, which then replaces the partial copy. Partial data
  /// is left in place on any error so the caller can resume or delete it.
  Future<int> downloadFile({
    required Uri url,
    required String destPath,
    required DownloadCancelToken token,
    String? referer,
    void Function(int received, int? total)? onProgress,
  }) async {
    token.throwIfStopped();
    final file = File(destPath);
    await file.parent.create(recursive: true);
    final offset = await file.exists() ? await file.length() : 0;
    final response = await open(url, referer: referer, rangeStart: offset);
    final status = response.statusCode;

    if (status == HttpStatus.requestedRangeNotSatisfiable && offset > 0) {
      final total = _rangeTotal(response);
      await _drainQuietly(response);
      if (total == offset) return offset; // Already complete.
      // The partial copy no longer matches the file; start over.
      await _deleteIfExists(file);
      return downloadFile(
        url: url,
        destPath: destPath,
        token: token,
        referer: referer,
        onProgress: onProgress,
      );
    }
    if (status >= 400) {
      await _drainQuietly(response);
      throw _statusError(status, 'Server returned $status');
    }

    final resuming = offset > 0 && status == HttpStatus.partialContent;
    final length = response.contentLength > 0 ? response.contentLength : null;
    final int? total = resuming
        ? (_rangeTotal(response) ?? (length == null ? null : offset + length))
        : length;
    final sink = file.openWrite(
      mode: resuming ? FileMode.writeOnlyAppend : FileMode.writeOnly,
    );
    var received = resuming ? offset : 0;
    onProgress?.call(received, total);
    try {
      await _pipe(response, sink, token, (n) {
        received += n;
        onProgress?.call(received, total);
      });
      await sink.flush();
      await sink.close();
    } catch (_) {
      await _closeQuietly(sink);
      rethrow;
    }
    if (total != null && received < total) {
      throw TransientDownloadException('The connection closed early.');
    }
    return received;
  }

  /// Downloads the segments of [plan] in order, concatenated into
  /// [destPath]. [cursor] records each finished segment, so a later call with
  /// the same cursor continues after the last whole segment (any partly
  /// written one is cut off first).
  Future<int> downloadSegments({
    required SegmentPlan plan,
    required String destPath,
    required DownloadCancelToken token,
    required SegmentCursor cursor,
    int? estimatedTotal,
    String? referer,
    void Function(int received, int? total)? onProgress,
  }) async {
    if (plan.encrypted) {
      throw DownloadException(
        'This stream is encrypted, so it cannot be saved.',
      );
    }
    final urls = <Uri>[if (plan.init != null) plan.init!, ...plan.segments];
    if (urls.isEmpty) {
      throw DownloadException('No downloadable media segments were found.');
    }
    token.throwIfStopped();
    final file = File(destPath);
    await file.parent.create(recursive: true);
    if (cursor.segmentsDone > 0) {
      final length = await file.exists() ? await file.length() : 0;
      if (length < cursor.bytesCommitted) {
        cursor.reset();
      } else if (length > cursor.bytesCommitted) {
        final raf = await file.open(mode: FileMode.append);
        try {
          await raf.truncate(cursor.bytesCommitted);
        } finally {
          await raf.close();
        }
      }
    }
    final sink = file.openWrite(
      mode: cursor.segmentsDone > 0
          ? FileMode.writeOnlyAppend
          : FileMode.writeOnly,
    );
    try {
      for (var i = cursor.segmentsDone; i < urls.length; i++) {
        token.throwIfStopped();
        final response = await open(urls[i], referer: referer);
        if (response.statusCode >= 400) {
          await _drainQuietly(response);
          throw _statusError(
            response.statusCode,
            'A segment failed (${response.statusCode})',
          );
        }
        var segmentBytes = 0;
        await _pipe(response, sink, token, (n) {
          segmentBytes += n;
          onProgress?.call(
            cursor.bytesCommitted + segmentBytes,
            estimatedTotal,
          );
        });
        await sink.flush();
        cursor
          ..bytesCommitted += segmentBytes
          ..segmentsDone = i + 1;
      }
      await sink.close();
    } catch (_) {
      await _closeQuietly(sink);
      rethrow;
    }
    return cursor.bytesCommitted;
  }

  /// Copies [response] into [sink], failing as transient when the connection
  /// stalls and ending at once (with the token's error) on pause or cancel,
  /// even if no bytes are arriving.
  Future<void> _pipe(
    HttpClientResponse response,
    IOSink sink,
    DownloadCancelToken token,
    void Function(int bytes) onChunk,
  ) {
    final done = Completer<void>();
    void finish([Object? error, StackTrace? stack]) {
      if (done.isCompleted) return;
      if (error == null) {
        done.complete();
      } else {
        done.completeError(error, stack);
      }
    }

    final subscription = response
        .timeout(
          stallTimeout,
          onTimeout: (events) {
            events.addError(
              TransientDownloadException('The connection stalled.'),
            );
            events.close();
          },
        )
        .listen(
          (chunk) {
            sink.add(chunk);
            onChunk(chunk.length);
          },
          onError: finish,
          onDone: finish,
          cancelOnError: true,
        );
    token.whenStopped.then((_) {
      subscription.cancel();
      finish(token.stopError);
    });
    return done.future;
  }

  DownloadException _statusError(int status, String message) =>
      status == HttpStatus.requestTimeout ||
          status == HttpStatus.tooManyRequests ||
          status >= 500
      ? TransientDownloadException(message)
      : DownloadException(message);

  /// Total size from a `Content-Range: bytes a-b/total` (or `*/total`).
  int? _rangeTotal(HttpClientResponse response) {
    final range = response.headers.value(HttpHeaders.contentRangeHeader);
    if (range == null) return null;
    final total = int.tryParse(range.split('/').last.trim());
    return total != null && total > 0 ? total : null;
  }

  Future<void> _drainQuietly(HttpClientResponse response) async {
    try {
      await response.drain<void>();
    } catch (_) {
      // The body is irrelevant.
    }
  }

  Future<void> _closeQuietly(IOSink sink) async {
    try {
      await sink.close();
    } catch (_) {
      // Already closed or failed; nothing else to do.
    }
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort cleanup.
    }
  }
}
