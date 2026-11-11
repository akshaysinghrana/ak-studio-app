import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/platform/youtube_dl.dart';
import '../../library/data/media_library_repository.dart';
import '../../library/presentation/widgets/media_tile.dart' show formatBytes;
import '../../playback/domain/media_source.dart';
import '../data/extractor_resolver.dart';
import '../data/link_resolver.dart';
import '../data/media_downloader.dart';
import '../domain/download_task.dart';
import '../domain/download_variant.dart';

/// Where in-progress downloads are written (app-private; no storage
/// permission). Finished files are published to Download/AS Media. This is
/// deliberately not the legacy `<documents>/downloads` folder, so the
/// one-time legacy migration never picks up a paused partial file.
final downloadsDirectoryProvider = FutureProvider<Directory>((ref) async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory(p.join(base.path, 'download_work'));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
});

final mediaDownloaderProvider = Provider<MediaDownloader>((ref) {
  final downloader = MediaDownloader();
  ref.onDispose(downloader.close);
  return downloader;
});

final linkResolverProvider = Provider<LinkResolver>(
  (ref) => LinkResolver(ref.watch(mediaDownloaderProvider)),
);

/// On-device extractor for YouTube/Facebook/Instagram/... links.
final extractorResolverProvider = Provider<ExtractorResolver>(
  (ref) => ExtractorResolver(ref.watch(youtubeDlProvider)),
);

final downloadControllerProvider =
    NotifierProvider<DownloadController, List<DownloadTask>>(
      DownloadController.new,
    );

/// Drives "paste a link" jobs: resolve -> offer options -> download -> index
/// the finished file into the library.
class DownloadController extends Notifier<List<DownloadTask>> {
  final _jobs = <String, _Job>{};
  final _startedMs = <String, int>{};
  final _startBytes = <String, int>{};
  final _lastEmitMs = <String, int>{};

  /// Latest progress per task, including ticks the UI throttle skipped, so a
  /// pause or a dropped connection records exactly how far it got.
  final _latest = <String, (int, int?)>{};
  var _sequence = 0;
  var _serviceRunning = false;
  var _lastServiceUpdateMs = 0;
  var _askedNotificationPermission = false;

  /// Consecutive failed attempts (with no bytes gained in between) before a
  /// download is reported as failed. With the backoff below this rides out
  /// roughly ten minutes without a connection.
  static const maxAutoRetries = 25;

  static Duration retryDelay(int attempt) =>
      Duration(seconds: attempt >= 5 ? 30 : 1 << attempt);

  @override
  List<DownloadTask> build() => const [];

  /// Begins resolving [rawUrl]. The task is added immediately so it can show a
  /// spinner, then either shows options or an error.
  Future<void> start(String rawUrl) async {
    final url = _normalizePastedUrl(rawUrl);
    if (url.isEmpty) return;
    final id = 'd${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
    state = [DownloadTask(id: id, url: url, title: _guessTitle(url)), ...state];
    try {
      final resolved = await _resolve(url);
      _update(
        id,
        (t) => t.copyWith(
          status: DownloadStatus.choosing,
          variants: resolved.variants,
          selected: resolved.variants.length == 1
              ? resolved.variants.first
              : null,
          note: resolved.note,
          title: resolved.title.isEmpty ? t.title : resolved.title,
        ),
      );
    } on DownloadException catch (e) {
      _fail(id, e.message);
    } catch (e) {
      _fail(id, 'Could not read that link: $e');
    }
  }

  /// Undo common Markdown escaping when a pasted link arrives with literal
  /// backslashes (for example `https\://host\.example/video\_id`).
  String _normalizePastedUrl(String raw) => raw
      .trim()
      .replaceAll(r'\:', ':')
      .replaceAll(r'\.', '.')
      .replaceAll(r'\_', '_');

  /// Resolves [url] without any server. Page URLs go through the on-device
  /// extractor first because it has site-specific extractors and handles
  /// redirects, anti-bot pages and player manifests. Direct media and manifest
  /// URLs keep using the built-in resolver. If yt-dlp cannot handle a page,
  /// the HTTP/HLS/DASH resolver remains the fallback.
  Future<ResolvedLink> _resolve(String url) async {
    final youtubeDl = ref.read(youtubeDlProvider);
    final available = await youtubeDl.isAvailable();
    ExtractorException? extractorError;

    if (available && !_isDirectMediaOrManifest(url)) {
      try {
        return await ref.read(extractorResolverProvider).resolve(url);
      } on ExtractorException catch (e) {
        extractorError = e;
      }
    }

    try {
      return await ref.read(linkResolverProvider).resolve(url);
    } on DownloadException {
      if (available && extractorError == null) {
        try {
          return await ref.read(extractorResolverProvider).resolve(url);
        } on ExtractorException catch (e) {
          extractorError = e;
        }
      }
      if (extractorError != null) {
        throw DownloadException(extractorError.message);
      }
      rethrow;
    }
  }

  bool _isDirectMediaOrManifest(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    final extension = path.contains('.') ? path.split('.').last : '';
    return const {
      'mp4',
      'm4v',
      'mov',
      'webm',
      'mkv',
      'ts',
      'm3u8',
      'mpd',
      'm4a',
      'mp3',
      'aac',
      'ogg',
      'opus',
      'wav',
      'flac',
    }.contains(extension);
  }

  /// Downloads [variant] (the user's chosen quality) for the task [id],
  /// discarding any partial data from an earlier choice.
  Future<void> download(String id, DownloadVariant variant) async {
    if (_byId(id) == null) return;
    final previous = _jobs.remove(id);
    if (previous != null) {
      previous.token?.cancel();
      await _discardPartial(id, previous);
    }
    _jobs[id] = _Job(variant);
    _update(id, (t) => t.copyWith(receivedBytes: 0, totalBytes: null));
    if (!_askedNotificationPermission) {
      _askedNotificationPermission = true;
      unawaited(
        ref.read(downloadServiceProvider).requestNotificationPermission(),
      );
    }
    await _run(id);
  }

  /// Stops [id] but keeps what was downloaded, so [resume] continues it.
  void pause(String id) => _jobs[id]?.token?.pause();

  /// Continues a paused download from where it stopped.
  Future<void> resume(String id) async {
    if (_byId(id)?.status != DownloadStatus.paused) return;
    await _run(id);
  }

  /// Runs (or continues) the transfer for [id], retrying by itself through
  /// dropped connections, then publishes the finished file to the library.
  Future<void> _run(String id) async {
    final job = _jobs[id];
    final task = _byId(id);
    if (job == null || task == null || job.token != null) return;
    final token = DownloadCancelToken();
    job.token = token;
    final variant = job.variant;
    _markStart(id, task.receivedBytes);
    _update(
      id,
      (t) => t.copyWith(
        status: DownloadStatus.downloading,
        selected: variant,
        totalBytes: t.totalBytes ?? variant.sizeBytes,
        bytesPerSecond: 0,
        error: null,
        transferNote: null,
      ),
    );
    try {
      final directory = await ref.read(downloadsDirectoryProvider.future);
      String destPath;
      int written;
      var failures = 0;
      var bytesAtFailure = -1;
      while (true) {
        try {
          (destPath, written) = await _transfer(id, job, token, directory);
          break;
        } catch (e) {
          if (token.isStopped || !_isTransient(e)) rethrow;
          _flushProgress(id);
          final received = _byId(id)?.receivedBytes ?? 0;
          // Only consecutive attempts that made no progress count.
          failures = received > bytesAtFailure ? 1 : failures + 1;
          bytesAtFailure = received;
          if (failures > maxAutoRetries) rethrow;
          final delay = retryDelay(failures);
          _update(
            id,
            (t) => t.copyWith(
              bytesPerSecond: 0,
              transferNote:
                  'Connection lost. Continuing in ${delay.inSeconds}s…',
            ),
          );
          await Future.any([Future<void>.delayed(delay), token.whenStopped]);
          token.throwIfStopped();
          _update(id, (t) => t.copyWith(transferNote: 'Reconnecting…'));
          _markStart(id, _byId(id)?.receivedBytes ?? 0);
        }
      }
      _update(
        id,
        (t) => t.copyWith(
          status: DownloadStatus.saving,
          receivedBytes: written,
          totalBytes: written,
          transferNote: null,
        ),
      );
      final displayName = p.basename(destPath);
      final mimeType = _mimeTypeFor(variant, displayName);
      // Publish into the public Downloads folder so the gallery and other
      // apps can see it; when that fails the app-private copy stays in place.
      final published = await ref
          .read(mediaStoreProvider)
          .publishDownload(
            sourcePath: destPath,
            displayName: displayName,
            mimeType: mimeType,
          );
      final locator = published ?? destPath;
      final entry = await ref
          .read(libraryRepositoryProvider)
          .registerDownload(
            locator: locator,
            title: _withoutExtension(task.title),
            displayName: displayName,
            kind: variant.kind,
            mimeType: mimeType,
            sizeBytes: written,
            width: variant.width,
            height: variant.height,
          );
      if (published != null) {
        // Public-only: once the file is safely in Download/AS Media, drop the
        // app-private copy (and the extractor's per-job folder). When
        // publishing failed the private copy stays so the file is not lost.
        await _deletePrivateCopy(directory, destPath);
      }
      _jobs.remove(id);
      _update(
        id,
        (t) => t.copyWith(
          status: DownloadStatus.done,
          savedPath: locator,
          savedItemId: entry.item.id,
          receivedBytes: written,
          totalBytes: written,
        ),
      );
    } on DownloadPaused {
      _paused(id);
    } on ExtractorPaused {
      _paused(id);
    } on DownloadCancelled {
      await _cancelled(id, job);
    } on ExtractorCancelled {
      await _cancelled(id, job);
    } on DownloadException catch (e) {
      _fail(id, e.message);
    } on ExtractorException catch (e) {
      _fail(id, e.message);
    } on SocketException {
      _fail(id, 'No connection. Tap Retry to continue where it stopped.');
    } on TimeoutException {
      _fail(id, 'The connection timed out. Tap Retry to continue.');
    } catch (e) {
      _fail(id, 'Download failed: $e');
    } finally {
      if (identical(job.token, token)) job.token = null;
      _syncService(force: true);
    }
  }

  /// One attempt at moving the bytes; returns the finished file and its
  /// size. Partial data is kept on any error so the next attempt resumes.
  Future<(String, int)> _transfer(
    String id,
    _Job job,
    DownloadCancelToken token,
    Directory directory,
  ) async {
    final variant = job.variant;
    if (variant.isExtractor) {
      final gateway = ref.read(youtubeDlProvider);
      final resume = job.extractorRuns > 0;
      // A fresh process id per run; the job folder (named by [id]) is what
      // carries the partial files from one run to the next.
      final runId = '$id-r${job.extractorRuns++}';
      final progressSub = gateway.progress.listen((event) {
        if (event.processId != runId) return;
        final total = variant.sizeBytes;
        _progress(
          id,
          total == null ? 0 : (event.progress * total).round(),
          total,
        );
      });
      final stopSub = token.whenStopped.asStream().listen((_) {
        token.isCancelled ? gateway.cancel(runId) : gateway.pause(runId);
      });
      try {
        final destPath = await gateway.download(
          url: variant.url.toString(),
          destDir: directory.path,
          processId: runId,
          jobId: id,
          format: variant.extractorFormat!,
          audioOnly: variant.audioOnly,
          resume: resume,
        );
        token.throwIfStopped();
        return (destPath, await File(destPath).length());
      } finally {
        await progressSub.cancel();
        await stopSub.cancel();
      }
    }

    final destPath = job.destPath ??= await _uniquePath(
      directory,
      _byId(id)?.title ?? 'download',
      variant.outputExtension,
    );
    final downloader = ref.read(mediaDownloaderProvider);
    final written = variant.isStream && variant.plan != null
        ? await downloader.downloadSegments(
            plan: variant.plan!,
            destPath: destPath,
            token: token,
            cursor: job.cursor,
            estimatedTotal: variant.sizeBytes,
            referer: variant.referer,
            onProgress: (received, total) =>
                _progress(id, received, total ?? variant.sizeBytes),
          )
        : await downloader.downloadFile(
            url: variant.url,
            destPath: destPath,
            token: token,
            referer: variant.referer,
            onProgress: (received, total) => _progress(id, received, total),
          );
    token.throwIfStopped();
    return (destPath, written);
  }

  /// Network-level failures that a later attempt can get past. yt-dlp
  /// already retries internally, so only connection-shaped errors from it
  /// are retried again here.
  bool _isTransient(Object error) {
    if (isTransientDownloadError(error)) return true;
    if (error is ExtractorException && error is! ExtractorCancelled) {
      return _extractorNetworkError.hasMatch(error.message);
    }
    return false;
  }

  static final _extractorNetworkError = RegExp(
    r'timed out|timeout|connection|network|unreachable|temporary failure|'
    r'getaddrinfo|resolve host|reset by peer|broken pipe|incompleteread|'
    r'errno|http error 5\d\d|http error 429|unable to download video data',
    caseSensitive: false,
  );

  void _paused(String id) {
    _flushProgress(id);
    _update(
      id,
      (t) => t.copyWith(
        status: DownloadStatus.paused,
        bytesPerSecond: 0,
        transferNote: null,
      ),
    );
  }

  Future<void> _cancelled(String id, _Job job) async {
    if (identical(_jobs[id], job)) _jobs.remove(id);
    await _discardPartial(id, job);
    _update(
      id,
      (t) => t.copyWith(
        status: DownloadStatus.failed,
        error: 'Download cancelled.',
        receivedBytes: 0,
        transferNote: null,
      ),
    );
  }

  /// Cancels [id]: a running transfer stops and its partial data is deleted;
  /// a paused or failed one has its partial data deleted straight away.
  void cancel(String id) {
    final job = _jobs[id];
    if (job == null) return;
    final token = job.token;
    if (token != null) {
      token.cancel();
      return;
    }
    unawaited(_cancelled(id, job));
  }

  /// Re-runs a failed download with the quality the user already picked,
  /// continuing from the partial file when there is one.
  Future<void> retry(String id) async {
    final task = _byId(id);
    if (task == null) return;
    if (_jobs.containsKey(id)) {
      await _run(id);
      return;
    }
    final variant = task.selected;
    if (variant != null) await download(id, variant);
  }

  /// Opens the system Files app at the folder downloads are saved into.
  Future<bool> openDownloadFolder() => ref
      .read(mediaStoreProvider)
      .openFolder(MediaLibraryRepository.downloadFolder);

  /// Deletes the saved file and its library entry, then removes the task.
  /// Returns false when the system delete prompt was declined.
  Future<bool> deleteSaved(String id) async {
    final itemId = _byId(id)?.savedItemId;
    if (itemId == null) return false;
    final repo = ref.read(libraryRepositoryProvider);
    final entry = await repo.byId(itemId);
    if (entry != null) {
      final ok = await repo.deleteFiles([entry.item], trash: false);
      if (!ok) return false;
      await ref.read(coordinatorProvider).removeMedia({itemId});
    }
    remove(id);
    return true;
  }

  /// Removes the task, stopping it and deleting any partial data first.
  void remove(String id) {
    cancel(id);
    _startedMs.remove(id);
    _startBytes.remove(id);
    _lastEmitMs.remove(id);
    state = [
      for (final t in state)
        if (t.id != id) t,
    ];
    _syncService(force: true);
  }

  void clearFinished() {
    for (final t in state) {
      if (!t.isActive && t.status != DownloadStatus.paused) cancel(t.id);
    }
    state = [
      for (final t in state)
        if (t.isActive || t.status == DownloadStatus.paused) t,
    ];
  }

  /// Writes the latest (possibly throttled) progress of [id] into state.
  void _flushProgress(String id) {
    final latest = _latest.remove(id);
    if (latest == null) return;
    final (received, total) = latest;
    _update(
      id,
      (t) => t.copyWith(
        receivedBytes: received,
        totalBytes: total ?? t.totalBytes,
      ),
    );
  }

  void _markStart(String id, int receivedBytes) {
    _startedMs[id] = DateTime.now().millisecondsSinceEpoch;
    _startBytes[id] = receivedBytes;
    _lastEmitMs[id] = 0;
  }

  void _progress(String id, int received, int? total) {
    _latest[id] = (received, total);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_lastEmitMs[id] ?? 0) < 200) return;
    _lastEmitMs[id] = now;
    final started = _startedMs[id];
    final fromBytes = _startBytes[id] ?? 0;
    var speed = 0.0;
    if (started != null && now > started && received >= fromBytes) {
      speed = (received - fromBytes) / ((now - started) / 1000);
    }
    _update(
      id,
      (t) => t.copyWith(
        receivedBytes: received,
        totalBytes: total ?? t.totalBytes,
        bytesPerSecond: speed,
        transferNote: null,
      ),
    );
  }

  /// Keeps the foreground service (and its notification) running exactly
  /// while something is transferring, so a backgrounded app is not frozen.
  void _syncService({bool force = false}) {
    final running = [
      for (final t in state)
        if (t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.saving)
          t,
    ];
    final service = ref.read(downloadServiceProvider);
    if (running.isEmpty) {
      if (_serviceRunning) {
        _serviceRunning = false;
        unawaited(service.stop());
      }
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && _serviceRunning && now - _lastServiceUpdateMs < 1000) return;
    _serviceRunning = true;
    _lastServiceUpdateMs = now;

    var received = 0;
    var total = 0;
    var totalsKnown = true;
    for (final t in running) {
      received += t.receivedBytes;
      final size = t.totalBytes;
      if (size == null || size <= 0) {
        totalsKnown = false;
      } else {
        total += size;
      }
    }
    final single = running.length == 1 ? running.first : null;
    final String text;
    if (single?.status == DownloadStatus.saving) {
      text = 'Saving to your library…';
    } else if (single?.transferNote != null) {
      text = single!.transferNote!;
    } else {
      text = totalsKnown && total > 0
          ? '${formatBytes(received)} of ${formatBytes(total)}'
          : formatBytes(received);
    }
    unawaited(
      service.update(
        title: single?.title ?? 'Downloading ${running.length} files',
        text: text,
        progress: totalsKnown && total > 0 ? received / total : null,
      ),
    );
  }

  DownloadTask? _byId(String id) {
    for (final task in state) {
      if (task.id == id) return task;
    }
    return null;
  }

  void _update(String id, DownloadTask Function(DownloadTask) transform) {
    state = [
      for (final task in state)
        if (task.id == id) transform(task) else task,
    ];
    _syncService();
  }

  void _fail(String id, String message) {
    _flushProgress(id);
    _update(
      id,
      (t) => t.copyWith(
        status: DownloadStatus.failed,
        error: message,
        bytesPerSecond: 0,
        transferNote: null,
      ),
    );
  }

  /// Deletes the partial data of [job]: the extractor's per-job folder or
  /// the direct download's working file.
  Future<void> _discardPartial(String id, _Job job) async {
    try {
      final directory = await ref.read(downloadsDirectoryProvider.future);
      if (job.variant.isExtractor) {
        final folder = Directory(p.join(directory.path, id));
        if (await folder.exists()) await folder.delete(recursive: true);
      } else {
        final path = job.destPath;
        if (path != null && await File(path).exists()) {
          await File(path).delete();
        }
      }
    } on FileSystemException {
      // Leftovers are harmless.
    } catch (_) {
      // No downloads folder (e.g. in tests).
    }
  }

  String _guessTitle(String url) {
    final uri = Uri.tryParse(url);
    final segments =
        uri?.pathSegments.where((s) => s.isNotEmpty).toList() ?? const [];
    return segments.isEmpty ? url : segments.last;
  }

  String _withoutExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// Removes the app-private working copy at [path] after it has been
  /// published to the public Downloads folder. The extractor writes into a
  /// per-job folder, which is removed too; a direct download only has its file
  /// removed (never the shared downloads folder itself).
  Future<void> _deletePrivateCopy(Directory root, String path) async {
    final file = File(path);
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      return;
    }
    final parent = file.parent;
    if (p.absolute(parent.path) == p.absolute(root.path)) return;
    try {
      if (await parent.exists()) await parent.delete(recursive: true);
    } on FileSystemException {
      // Leftovers are harmless.
    }
  }

  Future<String> _uniquePath(
    Directory directory,
    String baseName,
    String extension,
  ) async {
    final safe = _sanitize(_withoutExtension(baseName));
    var candidate = p.join(directory.path, '$safe.$extension');
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(directory.path, '$safe ($counter).$extension');
      counter++;
    }
    return candidate;
  }

  String _sanitize(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\-. ()\[\]&+]'), '_').trim();
    final limited = cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
    return limited.isEmpty ? 'download' : limited;
  }

  /// MIME type the finished file is published with, from its kind/ext.
  String _mimeTypeFor(DownloadVariant variant, String fileName) {
    if (variant.kind == MediaKind.video) return 'video/mp4';
    return switch (p.extension(fileName).toLowerCase()) {
      '.m4a' => 'audio/mp4',
      '.aac' => 'audio/aac',
      '.ogg' || '.opus' => 'audio/ogg',
      _ => 'audio/mpeg',
    };
  }
}

/// What a download needs to continue after a pause or a failed attempt.
class _Job {
  _Job(this.variant);

  final DownloadVariant variant;

  /// Working file of a direct or segmented download, fixed on first run.
  String? destPath;

  /// Progress through a segmented stream.
  final cursor = SegmentCursor();

  /// Extractor runs started so far; later runs resume the job folder.
  int extractorRuns = 0;

  /// Stop signal of the run in progress, or null when not running.
  DownloadCancelToken? token;
}
