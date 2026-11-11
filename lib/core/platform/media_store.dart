import 'package:flutter/services.dart';

import '../../features/library/domain/media_record.dart';
import '../../features/playback/domain/media_source.dart';

/// Access to Android's MediaStore and picked documents (ADR 0002).
abstract interface class MediaStoreGateway {
  Future<int> sdkInt();

  /// One page of MediaStore rows for [kind], newest first.
  Future<List<MediaRecord>> query(MediaKind kind, {int offset, int limit});

  /// Metadata for a user-picked document, or null if it is not MP4/MP3.
  Future<MediaRecord?> describe(String uri);

  /// Path of a cached JPEG thumbnail, or null when none can be produced.
  Future<String?> thumbnail(String uri, {int size});

  /// Copies the finished download at [sourcePath] into the public Downloads
  /// folder (visible to the gallery and other apps) and returns its new
  /// location: a `content://` URI, or a file path on old Android. Null when it
  /// could not be published, so the caller keeps the private copy.
  Future<String?> publishDownload({
    required String sourcePath,
    required String displayName,
    required String mimeType,
  });

  /// Opens the system file browser at [relativePath], e.g. `Download/AS Media`.
  Future<bool> openFolder(String relativePath);

  /// Moves files to the system trash (Android 11+) or deletes them
  /// permanently. Android asks the user to confirm; returns false when the
  /// user declines.
  Future<bool> deleteMedia(List<String> uris, {required bool trash});

  Future<bool> isTrashSupported();

  /// Fires (debounced) when MediaStore content changes, e.g. files deleted
  /// or added by other apps.
  Stream<void> changes();
}

class MethodChannelMediaStore implements MediaStoreGateway {
  const MethodChannelMediaStore();

  static const _channel = MethodChannel(
    'com.akshayrana.video_music_app/media_store',
  );

  @override
  Future<int> sdkInt() async => await _channel.invokeMethod<int>('sdkInt') ?? 0;

  @override
  Future<List<MediaRecord>> query(
    MediaKind kind, {
    int offset = 0,
    int limit = 500,
  }) async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'query',
      {'kind': kind.name, 'offset': offset, 'limit': limit},
    );
    return [
      for (final r in rows ?? const []) MediaRecord.fromPlatform(r, kind),
    ];
  }

  @override
  Future<MediaRecord?> describe(String uri) async {
    final m = await _channel.invokeMapMethod<Object?, Object?>('describe', {
      'uri': uri,
    });
    if (m == null) return null;
    final kind = MediaRecord.kindFor(
      mimeType: m['mimeType'] as String?,
      name: m['displayName'] as String?,
    );
    return kind == null ? null : MediaRecord.fromPlatform(m, kind);
  }

  @override
  Future<String?> thumbnail(String uri, {int size = 256}) =>
      _channel.invokeMethod<String>('thumbnail', {'uri': uri, 'size': size});

  @override
  Future<String?> publishDownload({
    required String sourcePath,
    required String displayName,
    required String mimeType,
  }) => _channel.invokeMethod<String>('publishDownload', {
    'sourcePath': sourcePath,
    'displayName': displayName,
    'mimeType': mimeType,
  });

  @override
  Future<bool> openFolder(String relativePath) async =>
      await _channel.invokeMethod<bool>('openFolder', {'path': relativePath}) ??
      false;

  static const _delete = MethodChannel(
    'com.akshayrana.video_music_app/media_delete',
  );
  static const _changes = EventChannel(
    'com.akshayrana.video_music_app/media_changes',
  );

  @override
  Future<bool> deleteMedia(List<String> uris, {required bool trash}) async =>
      await _delete.invokeMethod<bool>('delete', {
        'uris': uris,
        'trash': trash,
      }) ??
      false;

  @override
  Future<bool> isTrashSupported() async =>
      await _delete.invokeMethod<bool>('isTrashSupported') ?? false;

  @override
  Stream<void> changes() => _changes.receiveBroadcastStream().map((_) {});
}

/// System document picker with persistable read grants.
abstract interface class DocumentImporter {
  Future<List<String>> pickMedia();

  /// Picks one subtitle file; null when cancelled.
  Future<String?> pickSubtitle();

  /// Reads a small text document (subtitles, at most 2 MB).
  Future<String> readText(String uri);
  Future<void> release(String uri);
  Future<bool> hasAccess(String uri);
}

class MethodChannelDocumentImporter implements DocumentImporter {
  const MethodChannelDocumentImporter();

  static const _channel = MethodChannel(
    'com.akshayrana.video_music_app/documents',
  );

  @override
  Future<List<String>> pickMedia() async =>
      await _channel.invokeListMethod<String>('pickMedia') ?? const [];

  @override
  Future<String?> pickSubtitle() =>
      _channel.invokeMethod<String>('pickSubtitle');

  @override
  Future<String> readText(String uri) async =>
      await _channel.invokeMethod<String>('readText', {'uri': uri}) ?? '';

  @override
  Future<void> release(String uri) =>
      _channel.invokeMethod<void>('release', {'uri': uri});

  @override
  Future<bool> hasAccess(String uri) async =>
      await _channel.invokeMethod<bool>('hasAccess', {'uri': uri}) ?? false;
}
