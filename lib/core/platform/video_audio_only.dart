import 'package:flutter/services.dart';

/// Audio-only mode for background playback of videos (patched
/// video_player_android, see third_party/video_player_android/UMP_PATCH.md):
/// releases the video decoder while only the audio is heard.
class VideoAudioOnly {
  const VideoAudioOnly();

  static const _channel = MethodChannel(
    'com.akshayrana.video_music_app/video_player_ump',
  );

  Future<void> set(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setAudioOnly', enabled);
    } on MissingPluginException {
      // Tests and platforms without the patch: nothing to release.
    }
  }
}
