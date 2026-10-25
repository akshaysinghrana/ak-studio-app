enum MediaKind { audio, video }

/// A playable local file. [locator] is a file path or `content://` URI; it is a
/// locator, not a permanent identity (spec 4.1). [id] is the app's stable ID.
class MediaSource {
  const MediaSource({
    required this.id,
    required this.title,
    required this.locator,
    required this.kind,
  });

  final String id;
  final String title;
  final String locator;
  final MediaKind kind;

  static MediaKind? kindForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mp4')) return MediaKind.video;
    if (lower.endsWith('.mp3')) return MediaKind.audio;
    return null;
  }
}
