import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Keeps link downloads alive while the app is in the background.
///
/// On Android this is a `dataSync` foreground service with a progress
/// notification, a partial wake lock and a Wi-Fi lock. Without it Android
/// freezes a backgrounded app within seconds, which stalls in-flight
/// transfers until the server drops them.
abstract interface class DownloadServiceGateway {
  /// Starts the service, or updates its notification. [progress] is 0..1, or
  /// null when unknown.
  Future<void> update({
    required String title,
    required String text,
    double? progress,
  });

  /// Stops the service once nothing is downloading.
  Future<void> stop();

  /// Asks once for permission to show the progress notification (Android
  /// 13+). The service runs either way; only the notification is hidden.
  Future<void> requestNotificationPermission();
}

class MethodChannelDownloadService implements DownloadServiceGateway {
  const MethodChannelDownloadService();

  static const _channel = MethodChannel(
    'com.akshayrana.video_music_app/download_service',
  );

  @override
  Future<void> update({
    required String title,
    required String text,
    double? progress,
  }) async {
    try {
      await _channel.invokeMethod<bool>('update', {
        'title': title,
        'text': text,
        'progress': progress == null
            ? -1
            : (progress.clamp(0.0, 1.0) * 100).round(),
      });
    } on PlatformException {
      // Downloads still run while the app is open.
    } on MissingPluginException {
      // Not Android, or a test.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Already stopped.
    } on MissingPluginException {
      // Not Android, or a test.
    }
  }

  @override
  Future<void> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) await Permission.notification.request();
    } on PlatformException {
      // A request is already showing.
    } on MissingPluginException {
      // Not available in tests.
    }
  }
}

/// No-op gateway for tests and unsupported platforms.
class NoopDownloadService implements DownloadServiceGateway {
  const NoopDownloadService();

  @override
  Future<void> update({
    required String title,
    required String text,
    double? progress,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> requestNotificationPermission() async {}
}
