import '../../playback/domain/media_source.dart';

/// Adaptive streaming container that must be reassembled from its segments.
enum StreamKind { hls, dash }

/// The ordered pieces of a segmented stream: an optional initialisation
/// segment (fragmented MP4) followed by media segments, already resolved to
/// absolute URLs.
class SegmentPlan {
  const SegmentPlan({
    required this.segments,
    this.init,
    this.encrypted = false,
  });

  final List<Uri> segments;
  final Uri? init;

  /// True when the stream uses encryption (e.g. HLS AES-128) that the app
  /// cannot decrypt, so downloading must be refused with a clear message.
  final bool encrypted;

  bool get isEmpty => segments.isEmpty && init == null;
}

/// A selectable download option: a whole file, or one rendition of an
/// adaptive stream (HLS/DASH) that is rebuilt from its segments.
class DownloadVariant {
  const DownloadVariant({
    required this.label,
    required this.url,
    required this.kind,
    required this.outputExtension,
    this.referer,
    this.width,
    this.height,
    this.bandwidthBps,
    this.sizeBytes,
    this.sizeIsEstimate = false,
    this.stream,
    this.codecs,
    this.plan,
    this.extractorFormat,
    this.audioOnly = false,
  });

  /// HTTP `Referer` sent when fetching this media (and its segments). Many
  /// CDNs (e.g. xhamster) reject requests without the page that embedded them.
  /// Null for links the user pasted directly.
  final String? referer;

  /// Human label, e.g. "1080p · 5.1 Mbps" or "Audio only".
  final String label;
  final Uri url;
  final MediaKind kind;

  /// File extension the finished download is saved with (without the dot).
  final String outputExtension;

  final int? width;
  final int? height;
  final int? bandwidthBps;

  /// Known (Content-Length) or estimated (bitrate × duration) size in bytes.
  final int? sizeBytes;
  final bool sizeIsEstimate;

  /// Non-null when this option is an adaptive stream.
  final StreamKind? stream;
  final String? codecs;

  /// Segment plan for streams; null for direct files.
  final SegmentPlan? plan;

  /// Non-null when this option is produced by the on-device extractor (yt-dlp)
  /// rather than fetched directly: [url] is the page the user pasted and this
  /// holds the yt-dlp format selector. Null for ordinary links.
  final String? extractorFormat;

  /// True when the extractor should extract audio only (m4a).
  final bool audioOnly;

  bool get isExtractor => extractorFormat != null;

  bool get isStream => stream != null;

  /// e.g. "1920×1080", or null when the size is not reported.
  String? get resolution =>
      (width != null && height != null) ? '$width×$height' : null;
}
