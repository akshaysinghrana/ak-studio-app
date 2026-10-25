import 'package:flutter/services.dart';

/// Native bridge that decodes the real video frame at a position
/// (Android: MediaMetadataRetriever.OPTION_CLOSEST). Returns a PNG file path.
class FrameCapture {
  const FrameCapture();

  static const _channel = MethodChannel(
    'com.akshayrana.video_music_app/frame_capture',
  );

  Future<String> capture({
    required String locator,
    required Duration position,
  }) async {
    final path = await _channel.invokeMethod<String>('captureFrame', {
      'source': locator,
      'positionMs': position.inMilliseconds,
    });
    if (path == null) {
      throw PlatformException(code: 'capture_failed', message: 'No frame');
    }
    return path;
  }
}
