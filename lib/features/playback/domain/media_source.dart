enum MediaKind { audio, video }

/// A playable local file. [locator] is a file path or `content://` URI; it is a
/// locator, not a permanent identity (spec 4.1). [id] is the app's stable ID.
class MediaSource {
  const MediaSource({
    required this.id,
    required this.title,
    required this.locator,
    required this.kind,
    this.artist,
    this.album,
  });

  final String id;
  final String title;
  final String locator;
  final MediaKind kind;

  /// Tag metadata when present; never invented (spec 6.1).
  final String? artist;
  final String? album;

  /// Builds a source for a supported local file, or null for other types.
  /// Phase 1 uses the path as the ID; Phase 2 replaces it with a stable app ID.
  static MediaSource? fromFile({required String path, required String name}) {
    final kind = kindForFileName(name);
    if (kind == null) return null;
    return MediaSource(
      id: path,
      title: name.replaceAll(RegExp(r'\.(mp4|mp3)$', caseSensitive: false), ''),
      locator: path,
      kind: kind,
    );
  }

  static MediaKind? kindForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mp4')) return MediaKind.video;
    if (lower.endsWith('.mp3')) return MediaKind.audio;
    return null;
  }
}
