import '../../playback/domain/media_source.dart';

/// Metadata reported by the platform for one file (MediaStore row or picked
/// document). Values are never invented: absent metadata stays null.
class MediaRecord {
  const MediaRecord({
    required this.uri,
    required this.kind,
    this.storeId,
    this.displayName,
    this.title,
    this.mimeType,
    this.durationMs,
    this.sizeBytes,
    this.addedAt,
    this.modifiedAt,
    this.folder,
    this.width,
    this.height,
    this.artist,
    this.album,
  });

  final String uri;
  final MediaKind kind;
  final int? storeId;
  final String? displayName;
  final String? title;
  final String? mimeType;
  final int? durationMs;
  final int? sizeBytes;
  final DateTime? addedAt;
  final DateTime? modifiedAt;
  final String? folder;
  final int? width;
  final int? height;
  final String? artist;
  final String? album;

  MediaRecord copyWithUri(String uri) => MediaRecord(
    uri: uri,
    kind: kind,
    storeId: storeId,
    displayName: displayName,
    title: title,
    mimeType: mimeType,
    durationMs: durationMs,
    sizeBytes: sizeBytes,
    addedAt: addedAt,
    modifiedAt: modifiedAt,
    folder: folder,
    width: width,
    height: height,
    artist: artist,
    album: album,
  );

  /// Title shown in the library: the tag title, else the file name without
  /// its extension.
  String get bestTitle {
    final tag = title?.trim();
    if (tag != null && tag.isNotEmpty) return tag;
    final name = displayName ?? uri.split('/').last;
    return name.replaceAll(RegExp(r'\.(mp4|mp3)$', caseSensitive: false), '');
  }

  static MediaKind? kindFor({String? mimeType, String? name}) {
    if (mimeType == 'video/mp4') return MediaKind.video;
    if (mimeType == 'audio/mpeg') return MediaKind.audio;
    return name == null ? null : MediaSource.kindForFileName(name);
  }

  factory MediaRecord.fromPlatform(Map<Object?, Object?> m, MediaKind kind) {
    DateTime? fromSec(Object? v) => v is int && v > 0
        ? DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true)
        : null;
    String? str(Object? v) {
      final s = v as String?;
      return s == null || s.trim().isEmpty ? null : s;
    }

    int? positive(Object? v) => v is int && v > 0 ? v : null;
    return MediaRecord(
      uri: m['uri']! as String,
      kind: kind,
      storeId: m['storeId'] as int?,
      displayName: str(m['displayName']),
      title: str(m['title']),
      mimeType: str(m['mimeType']),
      durationMs: positive(m['durationMs']),
      sizeBytes: positive(m['sizeBytes']),
      addedAt: fromSec(m['dateAddedSec']),
      modifiedAt: fromSec(m['dateModifiedSec']),
      folder: str(m['folder']),
      width: positive(m['width']),
      height: positive(m['height']),
      artist: str(m['artist']),
      album: str(m['album']),
    );
  }
}
