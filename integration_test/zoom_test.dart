// On-device zoom/pan checks on the real ExoPlayer texture (spec 5.2). adb
// cannot inject multi-touch, so pinches are synthesized in the app.
// Run with scripts/run_device_engine_tests.sh <device-id> zoom_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_music_app/app/app.dart';
import 'package:video_music_app/app/providers.dart';
import 'package:video_music_app/app/router.dart';
import 'package:video_music_app/core/platform/picture_in_picture.dart';
import 'package:video_music_app/features/playback/application/playback_coordinator.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/shared/data/app_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pinch, pan, clamp, reset and double-tap on the video', (
    tester,
  ) async {
    final coordinator = await PlaybackCoordinator.init();
    final dir = '${(await getApplicationSupportDirectory()).path}/test_media';
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (!File('$dir/.ready').existsSync()) {
      if (DateTime.now().isAfter(deadline)) fail('Missing test media in $dir');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    // The debug engine screen hosts the same PlayerArea as Now Playing.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(
            AppDatabase(NativeDatabase.memory()),
          ),
          coordinatorProvider.overrideWithValue(coordinator),
          pictureInPictureProvider.overrideWithValue(PictureInPicture()),
        ],
        child: MediaPlayerApp(
          router: buildRouter(initialLocation: Routes.debugEngine),
        ),
      ),
    );
    await coordinator.playNow([
      MediaSource.fromFile(path: '$dir/ump_long.mp4', name: 'ump_long.mp4')!,
    ]);
    await coordinator.seek(const Duration(seconds: 20));
    await coordinator.pause();
    // Paused, so the tree settles; let the texture attach.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final viewer = find.byType(InteractiveViewer);
    expect(viewer, findsOneWidget);
    TransformationController transform() =>
        tester.widget<InteractiveViewer>(viewer).transformationController!;
    double scale() => transform().value.getMaxScaleOnAxis();
    final viewport = tester.getRect(viewer);
    final position = coordinator.controller.value!.value.position;

    /// Two fingers start [gap] apart and each moves [spread]/2 outward
    /// (negative = inward). Inward moves never let the fingers cross.
    Future<void> pinch(double spread, {double gap = 80}) async {
      assert(gap + spread > 0, 'fingers would cross');
      final c = viewport.center;
      final a = await tester.startGesture(c - Offset(gap / 2, 0), pointer: 1);
      final b = await tester.startGesture(c + Offset(gap / 2, 0), pointer: 2);
      for (var i = 0; i < 10; i++) {
        await a.moveBy(Offset(-spread / 20, 0));
        await b.moveBy(Offset(spread / 20, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await tester.pump(const Duration(milliseconds: 500));
    }

    /// With a zero boundary margin the zoomed child must still cover the
    /// whole viewport, i.e. the video can never be panned off-screen.
    void expectCoversViewport() {
      final m = transform().value;
      final s = m.getMaxScaleOnAxis();
      final t = m.getTranslation();
      final childRect = Rect.fromLTWH(
        t.x,
        t.y,
        viewport.width * s,
        viewport.height * s,
      );
      final local = Offset.zero & viewport.size;
      expect(childRect.inflate(1).contains(local.topLeft), isTrue);
      expect(childRect.inflate(1).contains(local.bottomRight), isTrue);
    }

    // Pinch out zooms in.
    await pinch(200);
    expect(scale(), greaterThan(1.5));
    expect(scale(), lessThanOrEqualTo(4.0));

    // Huge pinch is clamped to the 4x maximum.
    await pinch(2000);
    expect(scale(), closeTo(4.0, 0.01));

    // Panning hard in every direction keeps the video covering the viewport.
    for (final d in const [
      Offset(3000, 0),
      Offset(-3000, 0),
      Offset(0, 3000),
      Offset(0, -3000),
    ]) {
      await tester.dragFrom(viewport.center, d);
      await tester.pump(const Duration(milliseconds: 800));
      expectCoversViewport();
    }

    // Pinch in never goes below 1x (fingers end at 20% of their start gap,
    // so 4x would become 0.8x). Both fingers must start inside the viewport.
    final gap = viewport.width * 0.8;
    await pinch(-gap * 0.8, gap: gap);
    expect(scale(), closeTo(1.0, 0.01));

    // Explicit reset.
    await pinch(300);
    expect(scale(), greaterThan(1.2));
    await tester.tap(find.text('Reset zoom'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(scale(), closeTo(1.0, 0.001));

    // Double-tap toggles 2x and back, and never seeks.
    Future<void> doubleTap() async {
      await tester.tapAt(viewport.center);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(viewport.center);
      await tester.pump(const Duration(milliseconds: 500));
    }

    await doubleTap();
    expect(scale(), closeTo(2.0, 0.01));
    expectCoversViewport();
    await doubleTap();
    expect(scale(), closeTo(1.0, 0.01));

    final after = coordinator.controller.value!.value.position;
    expect((after - position).inMilliseconds.abs(), lessThan(200));
    expect(coordinator.controller.value!.value.isPlaying, isFalse);

    await coordinator.stop();
  });
}
