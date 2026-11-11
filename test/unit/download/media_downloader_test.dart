import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/download/data/media_downloader.dart';
import 'package:video_music_app/features/download/domain/download_variant.dart';

/// A local server for one test: serves [body] with Range support unless
/// [ignoreRange]; [onRequest] can take over a request (return true).
class _Server {
  _Server(this.body, {this.ignoreRange = false});

  final Uint8List body;
  final bool ignoreRange;
  final ranges = <String?>[];
  Future<bool> Function(HttpRequest request)? onRequest;
  late final HttpServer _server;

  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}/file.mp4');

  Uri segment(int i) => Uri.parse('http://127.0.0.1:${_server.port}/seg$i');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      ranges.add(request.headers.value(HttpHeaders.rangeHeader));
      if (onRequest != null && await onRequest!(request)) return;
      final response = request.response;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null && !ignoreRange) {
        final start = int.parse(range.substring(6, range.length - 1));
        if (start >= body.length) {
          response
            ..statusCode = HttpStatus.requestedRangeNotSatisfiable
            ..headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes */${body.length}',
            );
          await response.close();
          return;
        }
        response
          ..statusCode = HttpStatus.partialContent
          ..headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-${body.length - 1}/${body.length}',
          )
          ..contentLength = body.length - start
          ..add(body.sublist(start));
      } else {
        response
          ..contentLength = body.length
          ..add(body);
      }
      await response.close();
    });
  }

  Future<void> close() => _server.close(force: true);
}

Uint8List _bytes(int n) =>
    Uint8List.fromList(List<int>.generate(n, (i) => i % 251));

void main() {
  late Directory temp;
  late MediaDownloader downloader;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('downloader_test');
    downloader = MediaDownloader(stallTimeout: const Duration(seconds: 1));
  });

  tearDown(() async {
    downloader.close();
    await temp.delete(recursive: true);
  });

  test('resumes a partial file with an HTTP Range request', () async {
    final body = _bytes(5000);
    final server = _Server(body);
    await server.start();
    addTearDown(server.close);
    final path = '${temp.path}/a.mp4';
    await File(path).writeAsBytes(body.sublist(0, 1200));

    final written = await downloader.downloadFile(
      url: server.uri,
      destPath: path,
      token: DownloadCancelToken(),
    );

    expect(server.ranges, ['bytes=1200-']);
    expect(written, 5000);
    expect(await File(path).readAsBytes(), body);
  });

  test('replaces the partial copy when the server ignores ranges', () async {
    final body = _bytes(3000);
    final server = _Server(body, ignoreRange: true);
    await server.start();
    addTearDown(server.close);
    final path = '${temp.path}/b.mp4';
    await File(path).writeAsBytes(List<int>.filled(700, 9));

    final written = await downloader.downloadFile(
      url: server.uri,
      destPath: path,
      token: DownloadCancelToken(),
    );

    expect(written, 3000);
    expect(await File(path).readAsBytes(), body);
  });

  test('an already complete file is accepted without re-downloading', () async {
    final body = _bytes(800);
    final server = _Server(body);
    await server.start();
    addTearDown(server.close);
    final path = '${temp.path}/c.mp4';
    await File(path).writeAsBytes(body);

    final written = await downloader.downloadFile(
      url: server.uri,
      destPath: path,
      token: DownloadCancelToken(),
    );

    expect(written, 800);
    expect(await File(path).readAsBytes(), body);
  });

  test(
    'size probe sends the page Referer on its ranged GET fallback',
    () async {
      final server = _Server(Uint8List(0));
      await server.start();
      addTearDown(server.close);
      final referers = <String?>[];
      server.onRequest = (request) async {
        referers.add(request.headers.value(HttpHeaders.refererHeader));
        if (request.method == 'HEAD') {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          return true;
        }
        final response = request.response
          ..statusCode = HttpStatus.partialContent
          ..headers.set(HttpHeaders.contentRangeHeader, 'bytes 0-0/1200')
          ..contentLength = 1
          ..add([1]);
        await response.close();
        return true;
      };

      final size = await downloader.probeSize(
        server.uri,
        referer: 'https://javtiful.com/video/114857/jur-885',
      );

      expect(size, 1200);
      expect(referers, [
        'https://javtiful.com/video/114857/jur-885',
        'https://javtiful.com/video/114857/jur-885',
      ]);
    },
  );

  test('pause stops a stalled transfer at once and keeps the partial file, '
      'then resume finishes it', () async {
    final body = _bytes(4000);
    final server = _Server(body);
    await server.start();
    addTearDown(server.close);
    // First request: send 1000 bytes, then hang without closing.
    var first = true;
    final hung = Completer<void>();
    server.onRequest = (request) async {
      if (!first) return false;
      first = false;
      request.response
        ..bufferOutput = false
        ..contentLength = body.length
        ..add(body.sublist(0, 1000));
      await request.response.flush();
      hung.complete();
      return true;
    };
    final path = '${temp.path}/d.mp4';
    final token = DownloadCancelToken();
    final run = downloader.downloadFile(
      url: server.uri,
      destPath: path,
      token: token,
    );
    await hung.future;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    token.pause();

    await expectLater(run, throwsA(isA<DownloadPaused>()));
    expect(await File(path).length(), 1000);

    final written = await downloader.downloadFile(
      url: server.uri,
      destPath: path,
      token: DownloadCancelToken(),
    );
    expect(server.ranges.last, 'bytes=1000-');
    expect(written, 4000);
    expect(await File(path).readAsBytes(), body);
  });

  test(
    'a stalled connection fails as transient so it can be retried',
    () async {
      final body = _bytes(2000);
      final server = _Server(body);
      await server.start();
      addTearDown(server.close);
      server.onRequest = (request) async {
        request.response
          ..bufferOutput = false
          ..contentLength = body.length
          ..add(body.sublist(0, 500));
        await request.response.flush();
        return true; // Never finishes.
      };
      final path = '${temp.path}/e.mp4';

      Object? error;
      try {
        await downloader.downloadFile(
          url: server.uri,
          destPath: path,
          token: DownloadCancelToken(),
        );
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(isTransientDownloadError(error!), isTrue);
      expect(await File(path).length(), 500);
    },
  );

  test('server errors 5xx are transient, 4xx are not', () async {
    final server = _Server(_bytes(10));
    await server.start();
    addTearDown(server.close);
    var status = 503;
    server.onRequest = (request) async {
      request.response.statusCode = status;
      await request.response.close();
      return true;
    };
    Future<Object?> attempt() async {
      try {
        await downloader.downloadFile(
          url: server.uri,
          destPath: '${temp.path}/f.mp4',
          token: DownloadCancelToken(),
        );
      } catch (e) {
        return e;
      }
      return null;
    }

    expect(isTransientDownloadError((await attempt())!), isTrue);
    status = 404;
    final notFound = await attempt();
    expect(notFound, isA<DownloadException>());
    expect(isTransientDownloadError(notFound!), isFalse);
  });

  test('segmented download resumes after the last whole segment', () async {
    final segments = [_bytes(300), _bytes(400), _bytes(500)];
    final server = _Server(_bytes(1));
    await server.start();
    addTearDown(server.close);
    var failSecond = true;
    server.onRequest = (request) async {
      final index = int.parse(request.uri.path.substring(4));
      final data = segments[index];
      if (index == 1 && failSecond) {
        failSecond = false;
        // Half a segment, then the connection drops.
        request.response
          ..bufferOutput = false
          ..contentLength = data.length
          ..add(data.sublist(0, 150));
        await request.response.flush();
        // Ending short of Content-Length makes the server drop the socket.
        await request.response.close().catchError((_) {});
        return true;
      }
      request.response
        ..contentLength = data.length
        ..add(data);
      await request.response.close();
      return true;
    };
    final plan = SegmentPlan(
      segments: [for (var i = 0; i < 3; i++) server.segment(i)],
    );
    final path = '${temp.path}/g.ts';
    final cursor = SegmentCursor();

    Object? error;
    try {
      await downloader.downloadSegments(
        plan: plan,
        destPath: path,
        token: DownloadCancelToken(),
        cursor: cursor,
      );
    } catch (e) {
      error = e;
    }
    expect(isTransientDownloadError(error!), isTrue);
    expect(cursor.segmentsDone, 1);
    expect(cursor.bytesCommitted, 300);

    final written = await downloader.downloadSegments(
      plan: plan,
      destPath: path,
      token: DownloadCancelToken(),
      cursor: cursor,
    );
    expect(written, 1200);
    expect(await File(path).readAsBytes(), [
      ...segments[0],
      ...segments[1],
      ...segments[2],
    ]);
  });
}
