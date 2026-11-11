import '../../../core/platform/youtube_dl.dart';
import '../../playback/domain/media_source.dart';
import '../domain/download_variant.dart';
import 'link_resolver.dart';

/// Builds selectable download options from yt-dlp metadata (`--dump-json`).
///
/// Unlike [LinkResolver] (which yields direct media URLs), each option here
/// carries the original page URL plus a yt-dlp format selector; the on-device
/// extractor fetches it and ffmpeg merges video + audio. This is the
/// serverless path for YouTube/Facebook/Instagram/... links.
class ExtractorResolver {
  ExtractorResolver(this._youtubeDl);

  final YoutubeDlGateway _youtubeDl;

  /// Standard heights offered as separate options, tallest first.
  static const _tiers = [2160, 1440, 1080, 720, 480, 360, 240, 144];

  Future<ResolvedLink> resolve(String url) async {
    final info = await _youtubeDl.info(url);
    final title = (info['title'] as String?)?.trim() ?? '';
    final variants = _variants(url, info);
    if (variants.isEmpty) {
      throw const ExtractorException(
        'No downloadable video was found at that link.',
      );
    }
    return ResolvedLink(
      title: title.isEmpty ? _hostName(url) : title,
      variants: variants,
      note: 'Resolved on this device — no server needed.',
    );
  }

  List<DownloadVariant> _variants(String pageUrl, Map<String, dynamic> info) {
    final formats =
        (info['formats'] as List?)
            ?.whereType<Map>()
            .map((f) => f.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    final uri = Uri.tryParse(pageUrl);
    if (uri == null) return const [];

    final audioSize = _bestAudioSize(formats);
    final heights = <int>{
      for (final f in formats)
        if (_hasVideo(f) && (f['height'] as num?)?.toInt() != null)
          (f['height'] as num?)!.toInt(),
    }.where((h) => h > 0).toList()..sort((a, b) => b.compareTo(a));

    final offered = _tiers.where(heights.contains).take(6).toList();
    // Fall back to the actual heights when none match a standard tier.
    final tierHeights = offered.isNotEmpty ? offered : heights.take(6).toList();

    final variants = <DownloadVariant>[];
    for (var i = 0; i < tierHeights.length; i++) {
      final height = tierHeights[i];
      final width = _widthForHeight(formats, height);
      final videoSize = _videoSizeForHeight(formats, height);
      final total = videoSize == null ? null : videoSize + (audioSize ?? 0);
      variants.add(
        DownloadVariant(
          label:
              '${height}p'
              '${i == 0 ? ' · best' : ''}'
              '${audioSize != null ? ' · with audio' : ''}',
          url: uri,
          kind: MediaKind.video,
          outputExtension: 'mp4',
          width: width,
          height: height,
          sizeBytes: total,
          sizeIsEstimate: total != null,
          extractorFormat: 'bv*[height<=$height]+ba/b[height<=$height]',
        ),
      );
    }

    if (variants.isEmpty) {
      // No per-height formats (e.g. a single progressive file): offer best.
      variants.add(
        DownloadVariant(
          label: 'Best available',
          url: uri,
          kind: MediaKind.video,
          outputExtension: 'mp4',
          sizeBytes: _singleSize(info, formats),
          sizeIsEstimate: true,
          extractorFormat: 'bv*+ba/b',
        ),
      );
    }

    variants.add(
      DownloadVariant(
        label: 'Audio only · m4a',
        url: uri,
        kind: MediaKind.audio,
        outputExtension: 'm4a',
        sizeBytes: audioSize,
        sizeIsEstimate: audioSize != null,
        extractorFormat: 'ba/b',
        audioOnly: true,
      ),
    );
    return variants;
  }

  bool _hasVideo(Map<String, dynamic> f) {
    final vcodec = f['vcodec'];
    return vcodec is String && vcodec != 'none';
  }

  bool _hasAudio(Map<String, dynamic> f) {
    final acodec = f['acodec'];
    return acodec is String && acodec != 'none';
  }

  int? _sizeOf(Map<String, dynamic> f) {
    final exact = (f['filesize'] as num?)?.toInt();
    if (exact != null && exact > 0) return exact;
    final approx = (f['filesize_approx'] as num?)?.toInt();
    return (approx != null && approx > 0) ? approx : null;
  }

  /// Largest reported size among video renditions at [height] (the one yt-dlp
  /// would pick for `bv*[height<=H]`), or null when no size is reported.
  int? _videoSizeForHeight(List<Map<String, dynamic>> formats, int height) {
    int? best;
    for (final f in formats) {
      if (!_hasVideo(f)) continue;
      if ((f['height'] as num?)?.toInt() != height) continue;
      final size = _sizeOf(f);
      if (size != null && (best == null || size > best)) best = size;
    }
    return best;
  }

  int? _widthForHeight(List<Map<String, dynamic>> formats, int height) {
    for (final f in formats) {
      if (!_hasVideo(f)) continue;
      if ((f['height'] as num?)?.toInt() != height) continue;
      final width = (f['width'] as num?)?.toInt();
      if (width != null && width > 0) return width;
    }
    return null;
  }

  int? _bestAudioSize(List<Map<String, dynamic>> formats) {
    int? best;
    for (final f in formats) {
      if (!_hasAudio(f) || _hasVideo(f)) continue;
      final size = _sizeOf(f);
      if (size != null && (best == null || size > best)) best = size;
    }
    return best;
  }

  int? _singleSize(
    Map<String, dynamic> info,
    List<Map<String, dynamic>> formats,
  ) {
    final direct = (info['filesize'] as num?)?.toInt();
    if (direct != null && direct > 0) return direct;
    int? best;
    for (final f in formats) {
      final size = _sizeOf(f);
      if (size != null && (best == null || size > best)) best = size;
    }
    return best;
  }

  String _hostName(String raw) {
    final host = Uri.tryParse(raw)?.host ?? '';
    return host.startsWith('www.')
        ? host.substring(4)
        : (host.isEmpty ? 'download' : host);
  }
}
