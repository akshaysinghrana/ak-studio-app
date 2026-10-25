import 'package:flutter/services.dart';

/// Window-level screen controls (keep-awake, app brightness).
class ScreenControl {
  const ScreenControl();

  static const _channel = MethodChannel(
    'com.akshayrana.video_music_app/screen',
  );

  Future<void> keepOn(bool on) => _channel.invokeMethod<void>('keepOn', on);

  /// Sets this window's brightness (0..1); null restores the system value.
  Future<void> setBrightness(double? value) =>
      _channel.invokeMethod<void>('setBrightness', value);

  /// The window override, or null when following the system brightness.
  Future<double?> brightness() =>
      _channel.invokeMethod<double>('getBrightness');
}
