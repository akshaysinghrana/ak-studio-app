import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/playback/domain/background_policy.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';

void main() {
  test('audio always keeps playing in background', () {
    for (final setting in [true, false]) {
      expect(
        backgroundActionFor(
          kind: MediaKind.audio,
          continueVideoAudioInBackground: setting,
        ),
        BackgroundAction.keepPlaying,
      );
    }
  });

  test('video pauses in background when the setting is off', () {
    expect(
      backgroundActionFor(
        kind: MediaKind.video,
        continueVideoAudioInBackground: false,
      ),
      BackgroundAction.pauseAndSavePosition,
    );
  });

  test('video audio continues in background when the setting is on', () {
    expect(
      backgroundActionFor(
        kind: MediaKind.video,
        continueVideoAudioInBackground: true,
      ),
      BackgroundAction.keepPlaying,
    );
  });

  test('file extension maps to media kind', () {
    expect(MediaSource.kindForFileName('Clip.MP4'), MediaKind.video);
    expect(MediaSource.kindForFileName('song.mp3'), MediaKind.audio);
    expect(MediaSource.kindForFileName('doc.pdf'), isNull);
  });
}
