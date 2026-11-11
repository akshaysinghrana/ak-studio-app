import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/app/providers.dart';
import 'package:video_music_app/core/platform/download_service.dart';
import 'package:video_music_app/core/platform/youtube_dl.dart';
import 'package:video_music_app/features/download/application/download_controller.dart';
import 'package:video_music_app/features/download/data/link_resolver.dart';
import 'package:video_music_app/features/download/data/media_downloader.dart';
import 'package:video_music_app/features/download/domain/download_task.dart';
import 'package:video_music_app/features/download/domain/download_variant.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../../support/fakes.dart';

class _RecordingService implements DownloadServiceGateway {
  int updates = 0;
  int stops = 0;
  bool running = false;

  @override
  Future<void> update({
    required String title,
    required String text,
    double? progress,
  }) async {
    updates++;
    running = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    running = false;
  }

  @override
  Future<void> requestNotificationPermission() async {}
}

class _NoExtractor implements YoutubeDlGateway {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<Map<String, dynamic>> info(String url) => throw UnimplementedError();

  @override
  Future<String> download({
    required String url,
    required String destDir,
    required String processId,
    String? jobId,
    String format = '',
    bool audioOnly = false,
    bool resume = false,
  }) => throw UnimplementedError();

  @override
  Future<void> cancel(String processId) async {}

  @override
  Future<void> pause(String processId) async {}

  @override
  Stream<ExtractorProgress> get progress => const Stream.empty();
}

/// Resolves any link to one direct variant at [url].
class _FixedResolver extends LinkResolver {
  _FixedResolver(this.url, this.size) : super(MediaDownloader());

  final Uri url;
  final int size;

  @override
  Future<ResolvedLink> resolve(String raw) async => ResolvedLink(
    title: 'clip.mp4',
    variants: [
      DownloadVariant(
        label: 'Original',
        url: url,
        kind: MediaKind.video,
        outputExtension: 'mp4',
        sizeBytes: size,
      ),
    ],
  );
}

void main() {
  final body = Uint8List.fromList(List<int>.generate(6000, (i) => i % 241));
  late HttpServer server;
  late Directory temp;
  late AppDatabase db;
  late _RecordingService service;
  late ProviderContainer container;

  /// Decides how the server answers request number n (0-based). Return false
  /// to serve normally (honouring Range).
  late Future<bool> Function(HttpRequest request, int n) script;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('download_controller_test');
    db = memoryDatabase();
    service = _RecordingService();
    script = (_, _) async => false;
    var count = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final response = request.response..bufferOutput = false;
      if (await script(request, count++)) return;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      final start = range == null
          ? 0
          : int.parse(range.substring(6, range.length - 1));
      if (start > 0) {
        response
          ..statusCode = HttpStatus.partialContent
          ..headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-${body.length - 1}/${body.length}',
          );
      }
      response
        ..contentLength = body.length - start
        ..add(body.sublist(start));
      await response.close();
    });
    final url = Uri.parse('http://127.0.0.1:${server.port}/clip.mp4');
    final store = FakeMediaStore();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        mediaStoreProvider.overrideWithValue(store),
        libraryRepositoryProvider.overrideWithValue(
          MediaLibraryRepository(db, store, FakeDocumentImporter()),
        ),
        youtubeDlProvider.overrideWithValue(_NoExtractor()),
        downloadServiceProvider.overrideWithValue(service),
        downloadsDirectoryProvider.overrideWith((ref) async => temp),
        mediaDownloaderProvider.overrideWithValue(
          MediaDownloader(stallTimeout: const Duration(seconds: 1)),
        ),
        linkResolverProvider.overrideWithValue(
          _FixedResolver(url, body.length),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await server.close(force: true);
    await db.close();
    await temp.delete(recursive: true);
  });

  DownloadController controller() =>
      container.read(downloadControllerProvider.notifier);
  DownloadTask task() => container.read(downloadControllerProvider).single;

  Future<void> until(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out; task is ${task().status} ${task().error ?? ''}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> startAndPick() async {
    await controller().start('https://example.com/clip.mp4');
    expect(task().status, DownloadStatus.choosing);
  }

  test(
    'a dropped connection is retried and resumed instead of failing',
    () async {
      final ranges = <String?>[];
      script = (request, n) async {
        ranges.add(request.headers.value(HttpHeaders.rangeHeader));
        if (n != 0) return false;
        request.response
          ..contentLength = body.length
          ..add(body.sublist(0, 2500));
        await request.response.flush();
        // Ending short of Content-Length drops the connection.
        await request.response.close().catchError((_) {});
        return true;
      };
      await startAndPick();

      await controller().download(task().id, task().variants.single);

      expect(task().status, DownloadStatus.done, reason: task().error);
      expect(ranges, [null, 'bytes=2500-']);
      expect(await File(task().savedPath!).readAsBytes(), body);
      expect(service.updates, greaterThan(0));
      expect(service.running, isFalse);
    },
  );

  test('pause keeps the partial file and resume finishes it', () async {
    final ranges = <String?>[];
    final hold = Completer<void>();
    script = (request, n) async {
      ranges.add(request.headers.value(HttpHeaders.rangeHeader));
      if (n != 0) return false;
      request.response
        ..contentLength = body.length
        ..add(body.sublist(0, 1500));
      await request.response.flush();
      await hold.future; // Stays open until the test ends.
      return true;
    };
    addTearDown(() => hold.isCompleted ? null : hold.complete());
    await startAndPick();
    final id = task().id;

    final run = controller().download(id, task().variants.single);
    // Mid-transfer: the first bytes are in, the connection is still open.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(task().canPause, isTrue);
    controller().pause(id);
    await run;

    expect(task().status, DownloadStatus.paused);
    expect(task().receivedBytes, 1500);
    expect(service.running, isFalse);

    await controller().resume(id);

    expect(task().status, DownloadStatus.done, reason: task().error);
    expect(ranges.last, 'bytes=1500-');
    expect(await File(task().savedPath!).readAsBytes(), body);
  });

  test('cancelling a paused download deletes its partial file', () async {
    final hold = Completer<void>();
    script = (request, n) async {
      request.response
        ..contentLength = body.length
        ..add(body.sublist(0, 800));
      await request.response.flush();
      await hold.future;
      return true;
    };
    addTearDown(() => hold.isCompleted ? null : hold.complete());
    await startAndPick();
    final id = task().id;

    final run = controller().download(id, task().variants.single);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    controller().pause(id);
    await run;
    expect(task().status, DownloadStatus.paused);
    expect(task().receivedBytes, 800);
    expect(temp.listSync().whereType<File>(), hasLength(1));

    controller().cancel(id);
    await until(() => task().status == DownloadStatus.failed);

    expect(task().error, 'Download cancelled.');
    await until(() => temp.listSync().whereType<File>().isEmpty);
  });
}
