import 'package:flutter/services.dart';

/// Window-level screen controls (keep-awake, app brightness) and media
/// volume for the player gestures.
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

  /// Media volume as 0..1.
  Future<double> volume() async =>
      await _channel.invokeMethod<double>('getVolume') ?? 0;

  Future<void> setVolume(double fraction) =>
      _channel.invokeMethod<void>('setVolume', fraction);

  /// False when the app's battery use is optimised/restricted, which some
  /// manufacturers use to stop background playback.
  Future<bool> isBatteryUnrestricted() async =>
      await _channel.invokeMethod<bool>('isBatteryUnrestricted') ?? true;

  /// This app's package name and signing-certificate SHA-1, sent with
  /// Google API requests so keys restricted to the app are accepted.
  Future<({String? package, String? sha1})> appIdentity() async {
    try {
      final m = await _channel.invokeMapMethod<String, String?>('appIdentity');
      return (package: m?['package'], sha1: m?['sha1']);
    } on Exception {
      return (package: null, sha1: null);
    }
  }

  Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');
}
