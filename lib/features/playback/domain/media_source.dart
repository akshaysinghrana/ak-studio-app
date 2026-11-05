enum MediaKind { audio, video }

/// A playable item. [locator] is a file path or `content://` URI for local
/// media, or an `https://` stream for catalogue tracks (ADR 0004); it is a
/// locator, not a permanent identity (spec 4.1). [id] is the app's stable ID.
class MediaSource {
  const MediaSource({
    required this.id,
    required this.title,
    required this.locator,
    required this.kind,
    this.artist,
    this.album,
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String locator;
  final MediaKind kind;

  /// Tag metadata when present; never invented (spec 6.1).
  final String? artist;
  final String? album;

  /// Cover art provided by an online catalogue.
  final String? artworkUrl;

  /// Streamed from a catalogue; not a library item, so it has no saved
  /// progress, favourite or playlist membership until downloaded.
  bool get isOnline =>
      locator.startsWith('https://') || locator.startsWith('http://');

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
