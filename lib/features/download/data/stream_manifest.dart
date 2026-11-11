import '../domain/download_variant.dart';

/// Parsers for HLS (.m3u8) and DASH (.mpd) manifests. They are deliberately
/// lenient: the goal is to list downloadable renditions and their segments,
/// not to fully validate the manifests.

// ---------------------------------------------------------------------------
// Manifest sniffing

bool looksLikeHls(String text) => text.trimLeft().startsWith('#EXTM3U');

bool hlsHasMasterVariants(String text) => text.contains('#EXT-X-STREAM-INF');

bool looksLikeDash(String text) => text.contains('<MPD');

// ---------------------------------------------------------------------------
// Attribute helpers

final _attrPattern = RegExp(r'([A-Za-z_:][\w:.-]*)="([^"]*)"');

Map<String, String> _attrs(String tag) {
  final out = <String, String>{};
  for (final m in _attrPattern.allMatches(tag)) {
    out[m.group(1)!] = m.group(2)!;
  }
  return out;
}

String? _attr(String tag, String name) => _attrs(tag)[name];

List<String> _lines(String text) =>
    text.split('\n').map((l) => l.trim()).toList();

// ---------------------------------------------------------------------------
// HLS

class HlsRendition {
  const HlsRendition({
    required this.uri,
    this.bandwidthBps,
    this.width,
    this.height,
    this.codecs,
  });

  final Uri uri;
  final int? bandwidthBps;
  final int? width;
  final int? height;
  final String? codecs;
}

class HlsMedia {
  const HlsMedia({required this.plan, this.duration});

  final SegmentPlan plan;
  final Duration? duration;

  bool get encrypted => plan.encrypted;
}

/// One entry per `#EXT-X-STREAM-INF`.
List<HlsRendition> parseHlsMaster(String text, Uri base) {
  final lines = _lines(text);
  final out = <HlsRendition>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!line.startsWith('#EXT-X-STREAM-INF')) continue;
    final attrs = _attrs(line.substring(line.indexOf(':') + 1));
    var j = i + 1;
    while (j < lines.length && (lines[j].isEmpty || lines[j].startsWith('#'))) {
      j++;
    }
    if (j >= lines.length) break;
    final bandwidth = int.tryParse(
      attrs['AVERAGE-BANDWIDTH'] ?? attrs['BANDWIDTH'] ?? '',
    );
    final (width, height) = _parseResolution(attrs['RESOLUTION']);
    out.add(
      HlsRendition(
        uri: base.resolve(lines[j]),
        bandwidthBps: bandwidth,
        width: width,
        height: height,
        codecs: attrs['CODECS'],
      ),
    );
    i = j;
  }
  return out;
}

(int?, int?) _parseResolution(String? resolution) {
  if (resolution == null) return (null, null);
  final parts = resolution.split('x');
  if (parts.length != 2) return (null, null);
  return (int.tryParse(parts[0]), int.tryParse(parts[1]));
}

/// Parses a media playlist into a segment plan and, when present, its total
/// declared duration (the sum of `#EXTINF` values).
HlsMedia parseHlsMedia(String text, Uri base) {
  final lines = _lines(text);
  final segments = <Uri>[];
  Uri? init;
  var durationMs = 0;
  var encrypted = false;
  for (final line in lines) {
    if (line.startsWith('#EXT-X-KEY')) {
      final method = _attr(line.substring(line.indexOf(':') + 1), 'METHOD');
      if (method != null && method != 'NONE') encrypted = true;
    } else if (line.startsWith('#EXT-X-MAP')) {
      final uri = _attr(line.substring(line.indexOf(':') + 1), 'URI');
      if (uri != null && uri.isNotEmpty) init = base.resolve(uri);
    } else if (line.startsWith('#EXTINF')) {
      final value = line
          .substring(line.indexOf(':') + 1)
          .split(',')
          .first
          .trim();
      final secs = double.tryParse(value);
      if (secs != null && secs > 0) durationMs += (secs * 1000).round();
    } else if (line.isNotEmpty && !line.startsWith('#')) {
      segments.add(base.resolve(line));
    }
  }
  return HlsMedia(
    plan: SegmentPlan(segments: segments, init: init, encrypted: encrypted),
    duration: durationMs > 0 ? Duration(milliseconds: durationMs) : null,
  );
}

// ---------------------------------------------------------------------------
// DASH

class DashRepresentation {
  const DashRepresentation({
    required this.id,
    required this.plan,
    this.bandwidthBps,
    this.width,
    this.height,
    this.mimeType,
    this.codecs,
  });

  final String id;
  final SegmentPlan plan;
  final int? bandwidthBps;
  final int? width;
  final int? height;
  final String? mimeType;
  final String? codecs;

  bool get isAudio => (mimeType ?? '').startsWith('audio');
}

class DashManifest {
  const DashManifest({required this.representations, this.duration});

  final List<DashRepresentation> representations;
  final Duration? duration;
}

/// Parses the most common single-period DASH layouts (a shared
/// `SegmentTemplate` with `$Number$`/`$Time$`, optionally a
/// `SegmentTimeline`). Unsupported layouts yield empty segment plans so the
/// caller can report them clearly instead of downloading nothing.
DashManifest parseDash(String xml, Uri base) {
  final documentBase = _firstBaseUrl(xml, base);
  final durationAttr = RegExp(r'mediaPresentationDuration="([^"]+)"')
      .firstMatch(xml)
      ?.group(1);
  final totalDuration = durationAttr == null
      ? null
      : parseIsoDuration(durationAttr);

  final templateMatch = RegExp(
    r'<SegmentTemplate\b([^>]*?)/?>',
    dotAll: true,
  ).firstMatch(xml);
  final template = templateMatch == null
      ? const <String, String>{}
      : _attrs(templateMatch.group(1) ?? '');
  final mediaTemplate = template['media'];
  final initTemplate = template['initialization'];
  final timescale = int.tryParse(template['timescale'] ?? '') ?? 1;
  final segmentDuration = int.tryParse(template['duration'] ?? '');
  final startNumber = int.tryParse(template['startNumber'] ?? '') ?? 1;
  final timeline = RegExp(r'<SegmentTimeline>([\s\S]*?)</SegmentTimeline>')
      .firstMatch(xml)
      ?.group(1);

  final representations = <DashRepresentation>[];
  for (final m in RegExp(
    r'<Representation\b([^>]*?)/?>',
    dotAll: true,
  ).allMatches(xml)) {
    final attrs = _attrs(m.group(1) ?? '');
    final id = attrs['id'] ?? 'rep${representations.length}';
    final plan = mediaTemplate == null
        ? const SegmentPlan(segments: [])
        : SegmentPlan(
            init: initTemplate == null
                ? null
                : documentBase.resolve(
                    initTemplate.replaceAll(r'$RepresentationID$', id),
                  ),
            segments: _buildDashSegments(
              mediaTemplate: mediaTemplate,
              timelineXml: timeline,
              timescale: timescale,
              segmentDuration: segmentDuration,
              startNumber: startNumber,
              total: totalDuration,
              base: documentBase,
              replacements: {r'$RepresentationID$': id},
            ),
          );
    representations.add(
      DashRepresentation(
        id: id,
        plan: plan,
        bandwidthBps: int.tryParse(attrs['bandwidth'] ?? ''),
        width: int.tryParse(attrs['width'] ?? ''),
        height: int.tryParse(attrs['height'] ?? ''),
        mimeType: attrs['mimeType'],
        codecs: attrs['codecs'],
      ),
    );
  }
  return DashManifest(
    representations: representations,
    duration: totalDuration,
  );
}

List<Uri> _buildDashSegments({
  required String mediaTemplate,
  required String? timelineXml,
  required int timescale,
  required int? segmentDuration,
  required int startNumber,
  required Duration? total,
  required Uri base,
  required Map<String, String> replacements,
}) {
  Uri expand(String template, {int? number, int? time}) {
    var s = template;
    replacements.forEach((key, value) => s = s.replaceAll(key, value));
    if (number != null) s = s.replaceAll(r'$Number$', '$number');
    if (time != null) s = s.replaceAll(r'$Time$', '$time');
    s = s.replaceAll(r'$$', r'$');
    return base.resolve(s);
  }

  final out = <Uri>[];
  if (timelineXml != null && timelineXml.contains('<S')) {
    int time = 0;
    for (final m in RegExp(r'<S\b([^>]*)/?>').allMatches(timelineXml)) {
      final attrs = _attrs(m.group(1) ?? '');
      final start = int.tryParse(attrs['t'] ?? '');
      final duration = int.tryParse(attrs['d'] ?? '');
      final repeat = int.tryParse(attrs['r'] ?? '') ?? 0;
      if (duration == null) continue;
      if (start != null) time = start;
      for (var i = 0; i <= repeat; i++) {
        out.add(expand(mediaTemplate, time: time));
        time += duration;
      }
    }
    return out;
  }
  if (mediaTemplate.contains(r'$Number$')) {
    if (segmentDuration != null &&
        segmentDuration > 0 &&
        timescale > 0 &&
        total != null) {
      final segmentSeconds = segmentDuration / timescale;
      final count = (total.inMilliseconds / 1000 / segmentSeconds).ceil();
      for (var i = 0; i < count; i++) {
        out.add(expand(mediaTemplate, number: startNumber + i));
      }
    }
    return out;
  }
  // No placeholders: a single media URL.
  out.add(expand(mediaTemplate));
  return out;
}

Uri _firstBaseUrl(String xml, Uri base) {
  final m = RegExp(r'<BaseURL>([^<]+)</BaseURL>').firstMatch(xml);
  if (m == null) return base;
  return base.resolve(m.group(1)!.trim());
}

/// Parses an ISO-8601 duration such as `PT1H2M3.5S`.
Duration? parseIsoDuration(String value) {
  final m = RegExp(
    r'P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?'
    r'(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?)?',
  ).firstMatch(value);
  if (m == null) return null;
  int part(int index) => int.tryParse(m.group(index) ?? '') ?? 0;
  final seconds = double.tryParse(m.group(6) ?? '') ?? 0;
  return Duration(days: part(3), hours: part(4), minutes: part(5)) +
      Duration(milliseconds: (seconds * 1000).round());
}
