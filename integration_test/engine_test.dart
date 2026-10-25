// On-device engine checks for Phase 1 (spec 8.4 / 15). Run on a physical
// Android device with scripts/run_device_engine_tests.sh, which pushes the
// synthetic test media once the app is installed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_music_app/core/platform/frame_capture.dart';
import 'package:video_music_app/features/playback/application/playback_coordinator.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';

late PlaybackCoordinator coordinator;
late String mediaDir;

MediaSource media(String file) {
  final path = '$mediaDir/$file';
  if (!File(path).existsSync()) fail('Missing test media: $path');
  return MediaSource.fromFile(path: path, name: file)!;
}

Future<void> waitFor(
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'Timed out waiting for $what. '
        'engine: ${coordinator.controller.value?.value}, '
        'state: ${coordinator.playbackState.value}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Duration get position => coordinator.controller.value!.value.position;
bool get isPlaying => coordinator.controller.value?.value.isPlaying ?? false;

Future<void> load(List<String> files, {bool play = true}) async {
  await coordinator.playNow(files.map(media).toList());
  await waitFor('controller', () => coordinator.controller.value != null);
  if (!play) await coordinator.pause();
}

/// Settles the reported position after a seek on a paused player.
Future<Duration> settledPosition() async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  return position;
}

void expectNear(Duration actual, Duration expected, {int toleranceMs = 300}) {
  expect(
    (actual - expected).inMilliseconds.abs(),
    lessThanOrEqualTo(toleranceMs),
    reason: 'expected ~$expected, got $actual',
  );
}

/// Decodes the encoded second (mod 30) from the right half of a test-pattern
/// frame (see scripts/gen_test_media.sh).
Future<({int width, int height, int second, int grey})> decodeFrame(
  String path,
) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final x = image.width * 3 ~/ 4, y = image.height ~/ 2;
  final grey = data.getUint8((y * image.width + x) * 4);
  final limitedY = 16 + grey * 219 / 255;
  return (
    width: image.width,
    height: image.height,
    second: ((limitedY - 16) / 7).round(),
    grey: grey,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    coordinator = await PlaybackCoordinator.init();
    mediaDir = '${(await getExternalStorageDirectory())!.path}/test_media';
    // The runner pushes media after install and writes .ready last.
    await waitFor(
      'test media in $mediaDir',
      () => File('$mediaDir/.ready').existsSync(),
      timeout: const Duration(minutes: 3),
    );
  });

  tearDown(() => coordinator.stop());

  testWidgets('MP4 plays with real duration and advancing position', (t) async {
    await load(['ump_long.mp4']);
    expectNear(
      coordinator.controller.value!.value.duration,
      const Duration(seconds: 120),
      toleranceMs: 100,
    );
    await waitFor('playing', () => isPlaying);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(position, greaterThan(const Duration(milliseconds: 1500)));
    expect(coordinator.playbackState.value.playing, isTrue);
  });

  testWidgets('+/-10 s seeks are exact and clamped to bounds', (t) async {
    await load(['ump_long.mp4'], play: false);
    await coordinator.seek(const Duration(seconds: 30));
    expectNear(await settledPosition(), const Duration(seconds: 30));
    await coordinator.fastForward();
    expectNear(await settledPosition(), const Duration(seconds: 40));
    await coordinator.rewind();
    await coordinator.rewind();
    expectNear(await settledPosition(), const Duration(seconds: 20));
    await coordinator.seek(const Duration(seconds: 4));
    await coordinator.rewind();
    expectNear(await settledPosition(), Duration.zero);
    await coordinator.seek(const Duration(seconds: 115));
    await coordinator.fastForward();
    expectNear(await settledPosition(), const Duration(seconds: 120));
  });

  testWidgets('short clip (<10 s) clamps both directions', (t) async {
    await load(['ump_short.mp4'], play: false);
    await coordinator.seek(const Duration(seconds: 3));
    await coordinator.fastForward();
    expectNear(await settledPosition(), const Duration(seconds: 6));
    await coordinator.seek(const Duration(seconds: 3));
    await coordinator.rewind();
    expectNear(await settledPosition(), Duration.zero);
  });

  testWidgets('frame capture returns the decoded frame at the position', (
    t,
  ) async {
    for (final (file, w, h, seconds) in [
      ('ump_long.mp4', 1280, 720, [5, 37, 80, 113]),
      ('ump_portrait.mp4', 720, 1280, [2, 12, 27]),
    ]) {
      await load([file], play: false);
      for (final s in seconds) {
        await coordinator.seek(Duration(milliseconds: s * 1000 + 500));
        final at = await settledPosition();
        final path = await const FrameCapture().capture(
          locator: media(file).locator,
          position: at,
        );
        final frame = await decodeFrame(path);
        expect((frame.width, frame.height), (w, h), reason: file);
        expect(
          frame.second,
          s % 30,
          reason: '$file at $at, grey ${frame.grey}',
        );
      }
    }
  });

  testWidgets('MP3 plays as audio-only media', (t) async {
    await load(['ump_tone.mp3']);
    await waitFor('playing', () => isPlaying);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(position, greaterThan(const Duration(milliseconds: 1500)));
    expectNear(
      coordinator.controller.value!.value.duration,
      const Duration(seconds: 180),
      toleranceMs: 200,
    );
    expect(coordinator.mediaItem.value?.extras?['kind'], 'audio');
  });

  testWidgets('corrupt file reports an error instead of spinning', (t) async {
    await coordinator.playNow([media('ump_corrupt.mp4')]);
    await waitFor(
      'error state',
      () =>
          coordinator.playbackState.value.processingState ==
          AudioProcessingState.error,
    );
    expect(coordinator.playbackState.value.errorMessage, isNotNull);
    expect(coordinator.controller.value, isNull);
  });

  testWidgets('queue advances on completion and previous follows 3 s rule', (
    t,
  ) async {
    await load(['ump_short.mp4', 'ump_short_tone.mp3']);
    await waitFor(
      'advance to item 2',
      () => coordinator.playQueue.value.currentIndex == 1 && isPlaying,
      timeout: const Duration(seconds: 15),
    );
    expect(coordinator.mediaItem.value?.extras?['kind'], 'audio');
    // Regression: the system session must leave "loading" after an advance.
    await waitFor(
      'session ready+playing',
      () =>
          coordinator.playbackState.value.playing &&
          coordinator.playbackState.value.processingState ==
              AudioProcessingState.ready,
    );
    // Within 3 s: go to previous item.
    await coordinator.skipToPrevious();
    await waitFor(
      'back to item 1',
      () => coordinator.playQueue.value.currentIndex == 0 && isPlaying,
    );
    await waitFor(
      'session playing after previous',
      () =>
          coordinator.playbackState.value.playing &&
          coordinator.playbackState.value.queueIndex == 0,
    );
    // Past 3 s: restart the current item.
    await coordinator.skipToNext();
    await waitFor(
      'item 2',
      () => coordinator.playQueue.value.currentIndex == 1,
    );
    await waitFor('past 3 s', () => position > const Duration(seconds: 4));
    await coordinator.skipToPrevious();
    expect(coordinator.playQueue.value.currentIndex, 1);
    expect(await settledPosition(), lessThan(const Duration(seconds: 2)));
  });

  testWidgets('background policy pauses video only when the setting is off', (
    t,
  ) async {
    final binding = t.binding;
    Future<void> goBackground() async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    Future<void> goForeground() async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    // Setting off: video pauses, does not auto-resume on return.
    coordinator.continueVideoAudioInBackground.value = false;
    await load(['ump_long.mp4']);
    await waitFor('playing', () => isPlaying);
    await goBackground();
    expect(isPlaying, isFalse);
    await goForeground();
    expect(isPlaying, isFalse);

    // Setting on: keeps playing; turning it off while backgrounded pauses.
    coordinator.continueVideoAudioInBackground.value = true;
    await coordinator.play();
    await waitFor('playing', () => isPlaying);
    await goBackground();
    expect(isPlaying, isTrue);
    coordinator.continueVideoAudioInBackground.value = false;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(isPlaying, isFalse);
    await goForeground();

    // Audio ignores the setting and keeps playing.
    await load(['ump_tone.mp3']);
    await waitFor('playing', () => isPlaying);
    await goBackground();
    expect(isPlaying, isTrue);
    await goForeground();
  });
}
