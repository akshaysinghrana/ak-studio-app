import 'package:permission_handler/permission_handler.dart';

import '../../features/playback/domain/media_source.dart';
import '../platform/media_store.dart';

/// Result of a library-access check (ADR 0002).
enum MediaAccess {
  granted,

  /// Android 14+ "selected videos only": only chosen items are visible.
  limited,
  denied,

  /// Denied with "don't ask again"; only system settings can change it.
  permanentlyDenied,
}

abstract interface class MediaPermissions {
  Future<MediaAccess> status(MediaKind kind);

  /// Requests access just-in-time when the user starts a library scan.
  Future<Map<MediaKind, MediaAccess>> request();

  Future<bool> openSettings();
}

/// `permission_handler` implementation: READ_MEDIA_VIDEO/AUDIO on Android 13+,
/// READ_EXTERNAL_STORAGE below. Images are never requested.
class PlatformMediaPermissions implements MediaPermissions {
  PlatformMediaPermissions(this._store);

  final MediaStoreGateway _store;
  int? _sdk;

  Future<bool> get _granular async => (_sdk ??= await _store.sdkInt()) >= 33;

  Future<Permission> _permissionFor(MediaKind kind) async {
    if (!await _granular) return Permission.storage;
    return kind == MediaKind.video ? Permission.videos : Permission.audio;
  }

  static MediaAccess _map(PermissionStatus s) => switch (s) {
    PermissionStatus.granted => MediaAccess.granted,
    PermissionStatus.limited => MediaAccess.limited,
    PermissionStatus.permanentlyDenied => MediaAccess.permanentlyDenied,
    _ => MediaAccess.denied,
  };

  @override
  Future<MediaAccess> status(MediaKind kind) async =>
      _map(await (await _permissionFor(kind)).status);

  @override
  Future<Map<MediaKind, MediaAccess>> request() async {
    final video = await _permissionFor(MediaKind.video);
    final audio = await _permissionFor(MediaKind.audio);
    final results = await {video, audio}.toList().request();
    return {
      MediaKind.video: _map(results[video]!),
      MediaKind.audio: _map(results[audio]!),
    };
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
