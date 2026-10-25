import 'media_source.dart';

enum BackgroundAction { keepPlaying, pauseAndSavePosition }

/// Spec 8.2: audio always keeps playing in the background; video audio keeps
/// playing only when "Continue video audio in background" is enabled.
BackgroundAction backgroundActionFor({
  required MediaKind kind,
  required bool continueVideoAudioInBackground,
}) {
  if (kind == MediaKind.audio || continueVideoAudioInBackground) {
    return BackgroundAction.keepPlaying;
  }
  return BackgroundAction.pauseAndSavePosition;
}
