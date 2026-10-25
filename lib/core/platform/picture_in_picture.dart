import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android picture-in-picture bridge. PiP is only entered on explicit user
/// request, so the spec 8.2 "switch app pauses video" rule is unaffected.
class PictureInPicture {
  PictureInPicture() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipChanged') {
        isActive.value = call.arguments == true;
      }
    });
  }

  static const _channel = MethodChannel('com.akshayrana.video_music_app/pip');

  final ValueNotifier<bool> isActive = ValueNotifier(false);

  Future<bool> isSupported() async =>
      await _channel.invokeMethod<bool>('isSupported') ?? false;

  Future<bool> enter({required int width, required int height}) async =>
      await _channel.invokeMethod<bool>('enter', {
        'width': width,
        'height': height,
      }) ??
      false;
}
