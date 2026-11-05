import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/discover/domain/catalog.dart';
import 'package:video_music_app/features/downloads/application/download_manager.dart';
import 'package:video_music_app/features/downloads/data/download_engine.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/library/domain/media_record.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/features/playlists/data/playlist_repository.dart';
import 'package:video_music_app/features/settings/data/preferences_repository.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../../support/fakes.dart';

class FakeEngine implements DownloadEngine {
  FakeEngine(this.dir);

  final Directory dir;
  final _updates = StreamController<EngineUpdate>.broadcast();
  final enqueued = <EngineTask>[];
  final canceled = <String>[];
  final moved = <String>[];
  final statuses = <String, EngineStatus>{};
  int? concurrency;
  bool? wifiOnly;
  int permissionRequests = 0;

  void emit(EngineUpdate u) => _updates.add(u);

  @override
  Stream<EngineUpdate> get updates => _updates.stream;

  @override
  Future<void> start({required int concurrency, required bool wifiOnly}) async {
    this.concurrency = concurrency;
    this.wifiOnly = wifiOnly;
  }

  @override
  Future<void> setConcurrency(int c) async => concurrency = c;

  @override
  Future<void> setWifiOnly(bool w) async => wifiOnly = w;

  @override
  Future<bool> ensureNotificationPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<bool> enqueue(EngineTask task) async {
    enqueued.add(task);
    return true;
  }

  @override
  Future<bool> pause(String taskId) async => true;

  @override
  Future<bool> resume(String taskId) async => true;

  @override
  Future<void> cancel(String taskId) async => canceled.add(taskId);

  @override
  Future<EngineStatus?> statusOf(String taskId) async => statuses[taskId];

  @override
  Future<File> tempFile(EngineTask task) async =>
      File('${dir.path}/${task.taskId}_${task.fileName}');

  @override
  Future<String?> moveToShared(EngineTask task, MediaKind kind) async {
    final folder = kind == MediaKind.audio ? 'Music' : 'Movies';
    final path = '/storage/emulated/0/$folder/AS Media/${task.fileName}';
    moved.add(path);
    return path;
  }
}

const _mp3 = [0x49, 0x44, 0x33, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

CatalogTrack _track({String id = 't1', bool downloadable = true}) =>
    CatalogTrack(
      source: CatalogSource.audius,
      id: id,
      title: 'Night Drive',
      artist: 'Neon',
      streamUrl: 'https://api.audius.co/v1/tracks/$id/stream',
      downloadUrl: downloadable
          ? 'https://api.audius.co/v1/tracks/$id/stream'
          : null,
    );

void main() {
  late AppDatabase db;
  late FakeEngine engine;
  late FakeMediaStore store;
  late MediaLibraryRepository library;
  late PlaylistRepository playlists;
  late PreferencesRepository prefs;
  late DownloadManager manager;
  late Directory dir;
  UrlInfo probeResult = const UrlInfo();

  setUp(() async {
    db = memoryDatabase();
    dir = await Directory.systemTemp.createTemp('dl_test');
    engine = FakeEngine(dir);
    store = FakeMediaStore();
    library = MediaLibraryRepository(
      db,
      store,
      FakeDocumentImporter(),
      emptyScanRecheckDelay: Duration.zero,
    );
    playlists = PlaylistRepository(db);
    prefs = PreferencesRepository(db);
    probeResult = const UrlInfo();
    manager = DownloadManager(
      db: db,
      engine: engine,
      preferences: prefs,
      library: library,
      playlists: playlists,
      refreshLibrary: (kind) => library.scanMediaStore({kind}),
      probe: (_) async => probeResult,
      libraryWait: Duration.zero,
    );
    await manager.init();
  });

  tearDown(() async {
    await manager.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<DownloadRow> row(String id) =>
      (db.select(db.downloads)..where((t) => t.id.equals(id))).getSingle();

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('init applies saved concurrency and Wi-Fi settings', () async {
    expect(engine.concurrency, 2);
    expect(engine.wifiOnly, isFalse);
    await manager.setConcurrency(3);
    await manager.setWifiOnly(true);
    expect(engine.concurrency, 3);
    expect(engine.wifiOnly, isTrue);
    expect(await prefs.downloadConcurrency(), 3);
    expect(await prefs.downloadWifiOnly(), isTrue);
  });

  test('a track the artist did not allow is refused', () async {
    final r = await manager.downloadTrack(_track(downloadable: false));
    expect(r, isA<DownloadRejected>());
    expect(engine.enqueued, isEmpty);
  });

  test('full flow: progress, validate, save, library and playlist', () async {
    final started = await manager.downloadTrack(_track()) as DownloadStarted;
    final task = engine.enqueued.single;
    expect(task.fileName, 'Neon - Night Drive.mp3');
    expect(engine.permissionRequests, 1);

    engine.emit(
      EngineUpdate(
        taskId: task.taskId,
        progress: 0.5,
        bytesPerSecond: 1000,
        totalBytes: 2000,
      ),
    );
    await settle();
    var r = await row(started.row.id);
    expect(r.status, DownloadStatus.running);
    expect(r.progress, 0.5);
    expect(manager.live.value[r.id]?.bytesPerSecond, 1000);

    // The finished file lands in app storage, then MediaStore indexes it.
    await (await engine.tempFile(task)).writeAsBytes(_mp3);
    store.audio = [
      const MediaRecord(
        uri: 'content://media/external/audio/media/77',
        kind: MediaKind.audio,
        storeId: 77,
        displayName: 'Neon - Night Drive.mp3',
        folder: 'Music/AS Media/',
        durationMs: 1000,
      ),
    ];
    engine.emit(
      EngineUpdate(taskId: task.taskId, status: EngineStatus.complete),
    );
    await settle();
    await settle();

    r = await row(started.row.id);
    expect(r.status, DownloadStatus.complete);
    expect(
      r.savedPath,
      '/storage/emulated/0/Music/AS Media/Neon - Night Drive.mp3',
    );
    expect(manager.live.value.containsKey(r.id), isFalse);
    final item = await manager.libraryItemFor(r);
    expect(item, isNotNull);
    final lists = await playlists.watchPlaylists().first;
    expect(lists.single.playlist.name, DownloadManager.downloadsPlaylist);
    expect(lists.single.count, 1);
  });

  test('an invalid file fails instead of reaching the library', () async {
    final started = await manager.downloadTrack(_track()) as DownloadStarted;
    final task = engine.enqueued.single;
    await (await engine.tempFile(task)).writeAsString('<html>error</html>');
    engine.emit(
      EngineUpdate(taskId: task.taskId, status: EngineStatus.complete),
    );
    await settle();
    final r = await row(started.row.id);
    expect(r.status, DownloadStatus.failed);
    expect(r.error, contains('not an MP3'));
    expect(engine.moved, isEmpty);
  });

  test('duplicates are detected until forced', () async {
    await manager.downloadTrack(_track());
    final again = await manager.downloadTrack(_track());
    expect(again, isA<DownloadDuplicate>());
    final forced = await manager.downloadTrack(_track(), force: true);
    expect(forced, isA<DownloadStarted>());
    expect(engine.enqueued, hasLength(2));
  });

  test('retry restarts with a new task; cancel and remove', () async {
    final started = await manager.downloadTrack(_track()) as DownloadStarted;
    final first = engine.enqueued.single.taskId;
    engine.emit(
      EngineUpdate(
        taskId: first,
        status: EngineStatus.failed,
        error: 'The connection was lost.',
      ),
    );
    await settle();
    expect((await row(started.row.id)).error, 'The connection was lost.');

    await manager.retry(started.row.id);
    final r = await row(started.row.id);
    expect(r.taskId, isNot(first));
    expect(r.status, DownloadStatus.waiting);
    expect(r.error, isNull);
    expect(engine.enqueued.last.taskId, r.taskId);

    await manager.cancel(r.id);
    expect(engine.canceled, [r.taskId]);
    expect((await row(r.id)).status, DownloadStatus.canceled);
    await manager.remove(r.id);
    expect(await db.select(db.downloads).get(), isEmpty);
  });

  group('direct links', () {
    test('YouTube links are refused before any request', () async {
      final r = await manager.downloadUrl('https://youtu.be/abc');
      expect(r, isA<DownloadRejected>());
      expect(engine.enqueued, isEmpty);
    });

    test('redirects to YouTube are refused', () async {
      probeResult = UrlInfo(
        mimeType: 'video/mp4',
        finalUrl: Uri.parse('https://r1.googlevideo.com/videoplayback'),
      );
      final r = await manager.downloadUrl('https://short.link/x');
      expect((r as DownloadRejected).reason, contains('YouTube'));
    });

    test('non-media content is refused', () async {
      probeResult = const UrlInfo(mimeType: 'text/html');
      final r = await manager.downloadUrl('https://example.com/page');
      expect((r as DownloadRejected).reason, contains('MP3 or MP4'));
    });

    test('an MP4 link becomes a video download named from the URL', () async {
      probeResult = const UrlInfo(mimeType: 'video/mp4');
      final r = await manager.downloadUrl(
        'https://cdn.example/files/My%20Clip.mp4',
      ) as DownloadStarted;
      expect(r.row.kind, MediaKind.video);
      expect(r.row.title, 'My Clip');
      expect(r.row.fileName, 'My Clip.mp4');
      expect(r.row.source, 'url');
    });
  });

  test('downloads finished while the app was closed are completed', () async {
    final started = await manager.downloadTrack(_track()) as DownloadStarted;
    final task = engine.enqueued.single;
    await (await engine.tempFile(task)).writeAsBytes(_mp3);
    engine.statuses[task.taskId] = EngineStatus.complete;
    await manager.dispose();

    manager = DownloadManager(
      db: db,
      engine: engine,
      preferences: prefs,
      library: library,
      playlists: playlists,
      refreshLibrary: (kind) async {},
      probe: (_) async => probeResult,
      libraryWait: Duration.zero,
    );
    await manager.init();
    final r = await row(started.row.id);
    expect(r.status, DownloadStatus.complete);
    expect(engine.moved, hasLength(1));
  });
}
