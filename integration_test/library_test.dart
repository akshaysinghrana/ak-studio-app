// On-device Phase 2 checks against the real MediaStore (ADR 0002). Run with
// scripts/run_device_library_test.sh <device-id>, which places synthetic
// files in Movies/UMP_Test and Music/UMP_Test, grants media permissions and
// removes everything afterwards. Uses an in-memory database.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_music_app/core/permissions/media_permissions.dart';
import 'package:video_music_app/core/platform/frame_capture.dart';
import 'package:video_music_app/core/platform/media_store.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/playback/application/playback_coordinator.dart';
import 'package:video_music_app/features/playback/data/drift_progress_store.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/shared/data/app_database.dart';

Future<void> waitFor(
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for $what');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MediaLibraryRepository repo;
  late PlaybackCoordinator coordinator;
  const store = MethodChannelMediaStore();

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = MediaLibraryRepository(
      db,
      store,
      const MethodChannelDocumentImporter(),
    );
    coordinator = await PlaybackCoordinator.init(
      progressStore: DriftPlaybackProgressStore(db),
      onLoadError: (m) => repo.verifyAvailability(m.id),
    );
  });

  Future<LibraryEntry> find(MediaKind kind, String title) async {
    final all = await repo.watch(kind, search: title).first;
    return all.firstWhere(
      (e) => e.item.title == title,
      orElse: () => fail('"$title" not found in MediaStore scan'),
    );
  }

  testWidgets('permissions granted by the runner are reported', (t) async {
    final permissions = PlatformMediaPermissions(store);
    expect(await permissions.status(MediaKind.video), MediaAccess.granted);
    expect(await permissions.status(MediaKind.audio), MediaAccess.granted);
  });

  testWidgets('scan indexes MP4/MP3 with real MediaStore metadata', (t) async {
    final summary = await repo.scanMediaStore(MediaKind.values.toSet());
    expect(summary.added, greaterThanOrEqualTo(3));

    final video = await find(MediaKind.video, 'ump_long');
    expect(video.item.locator, startsWith('content://media/external/video/'));
    expect(video.item.mimeType, 'video/mp4');
    expect(video.item.durationMs, closeTo(120000, 200));
    expect(video.item.width, 1280);
    expect(video.item.height, 720);
    expect(video.item.folder, 'Movies/UMP_Test/');

    final song = await find(MediaKind.audio, 'UMP Test Tone');
    expect(song.item.artist, 'Synthetic');
    // No album tag in the file: must stay null, never "<unknown>".
    expect(song.item.album, isNull);
    expect(song.item.durationMs, closeTo(180000, 300));

    // Rescan is idempotent: same IDs, nothing added.
    final again = await repo.scanMediaStore(MediaKind.values.toSet());
    expect(again.added, 0);
    expect((await find(MediaKind.video, 'ump_long')).item.id, video.item.id);
  });

  testWidgets('thumbnails are generated without reading whole files', (
    t,
  ) async {
    final video = await find(MediaKind.video, 'ump_long');
    final path = await store.thumbnail(video.item.locator);
    expect(path, isNotNull);
    final codec = await ui.instantiateImageCodec(
      await File(path!).readAsBytes(),
    );
    final image = (await codec.getNextFrame()).image;
    expect(image.width, lessThanOrEqualTo(512));
    expect(image.width, greaterThan(0));
  });

  testWidgets('content:// items play, capture frames and resume', (t) async {
    final video = await find(MediaKind.video, 'ump_long');
    await coordinator.playNow([video.toMediaSource()]);
    await waitFor('controller', () => coordinator.controller.value != null);
    await waitFor(
      'playing',
      () => coordinator.controller.value!.value.isPlaying,
    );
    await coordinator.seek(const Duration(seconds: 45));
    await coordinator.pause();
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Frame capture works on the MediaStore URI too.
    final position = coordinator.controller.value!.value.position;
    final png = await const FrameCapture().capture(
      locator: video.item.locator,
      position: position,
    );
    expect(File(png).existsSync(), isTrue);

    // Pause persisted progress to the database (written asynchronously).
    final progress = DriftPlaybackProgressStore(db);
    Duration? saved;
    for (var i = 0; i < 30 && saved == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      saved = await progress.resumePosition(video.item.id);
    }
    expect(saved!.inMilliseconds, closeTo(45000, 600));

    // Switching away and back resumes at the saved position.
    final song = await find(MediaKind.audio, 'UMP Test Tone');
    await coordinator.playNow([song.toMediaSource()]);
    await waitFor(
      'song',
      () => coordinator.mediaItem.value?.title == 'UMP Test Tone',
    );
    await coordinator.playNow([video.toMediaSource()]);
    await waitFor(
      'video resumed',
      () =>
          coordinator.controller.value != null &&
          coordinator.mediaItem.value?.title == 'ump_long',
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(
      coordinator.controller.value!.value.position.inMilliseconds,
      closeTo(45000, 1500),
    );
    final continueList = await repo.watchContinue().first;
    expect(continueList.map((e) => e.item.id), contains(video.item.id));
    await coordinator.stop();
  });
}
