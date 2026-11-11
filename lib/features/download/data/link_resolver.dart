import 'dart:convert';
import 'dart:io';

import '../../playback/domain/media_source.dart';
import '../domain/download_variant.dart';
import 'media_downloader.dart';
import 'stream_manifest.dart';

/// The result of interpreting a pasted link: the download options it yields,
/// plus a title and an optional note for the UI.
class ResolvedLink {
  const ResolvedLink({required this.title, required this.variants, this.note});

  final String title;
  final List<DownloadVariant> variants;
  final String? note;
}

const _directExtensions = {
  'mp4',
  'm4v',
  'mov',
  'webm',
  'mkv',
  'ts',
  'm4a',
  'mp3',
  'aac',
  'ogg',
  'opus',
  'wav',
  'flac',
};

const _audioExtensions = {'mp3', 'm4a', 'aac', 'ogg', 'opus', 'wav', 'flac'};

/// Turns any pasted link into downloadable options:
///  * a direct media file -> one option (with its size);
///  * an HLS (.m3u8) / DASH (.mpd) stream -> one option per rendition;
///  * a web page -> the media it references, including an `.m3u8`/`.mpd` that
///    a `blob:` player hides behind its scripts.
class LinkResolver {
  LinkResolver(this._downloader);

  final MediaDownloader _downloader;

  static const _maxPageCandidates = 12;
  static const _maxEmbeddedPages = 6;
  static const _maxEmbedDepth = 3;
  static const _maxTextBytes = 2 * 1024 * 1024;

  Future<ResolvedLink> resolve(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme) {
      throw DownloadException('That does not look like a link.');
    }
    if (uri.scheme == 'blob') {
      throw DownloadException(
        'blob: links only exist inside the browser page that created them, so '
        'they cannot be opened directly. Copy the page address instead and '
        'paste it here — the app will look for the video (including any .m3u8 '
        'stream) itself.',
      );
    }
    if (uri.scheme != 'https') {
      throw DownloadException(
        'Only secure (https) links can be downloaded. Plain http links are '
        'not encrypted and are blocked by Android.',
      );
    }

    // ePorner's public page metadata has a direct MP4 contentUrl. Resolve this
    // video host directly with the supplied page as Referer, which also avoids
    // trying poster and ad URLs present elsewhere in its markup.
    if (uri.host == 'eporner.com' || uri.host.endsWith('.eporner.com')) {
      try {
        final html = await _downloader.fetchText(uri);
        final normalized = _normalizeEmbeddedText(html);
        final match = RegExp(
          r'''["']contentUrl["']\s*:\s*["'](https://gvideo\.eporner\.com/[^"']+?\.mp4(?:\?[^"']*)?)["']''',
          caseSensitive: false,
        ).firstMatch(normalized);
        if (match != null) {
          final mediaUri = Uri.tryParse(match.group(1)!);
          if (mediaUri != null) {
            final size = await _downloader.probeSize(
              mediaUri,
              referer: uri.toString(),
            );
            return ResolvedLink(
              title: _pageTitle(html) ?? _fileName(uri),
              variants: [
                DownloadVariant(
                  label: 'Video file',
                  url: mediaUri,
                  referer: uri.toString(),
                  kind: MediaKind.video,
                  outputExtension: 'mp4',
                  sizeBytes: size,
                ),
              ],
              note: 'Found the ePorner video source.',
            );
          }
        }
      } on Exception {
        // Continue through the general page and extractor fallbacks.
      }
    }

    final extension = _extension(uri.path);
    if (extension == 'm3u8') return _resolveHls(uri);
    if (extension == 'mpd') return _resolveDash(uri);
    if (_directExtensions.contains(extension)) return _resolveDirect(uri);
    return _resolveByResponse(uri);
  }

  // ---------------------------------------------------------------------------
  // Classification by response headers

  Future<ResolvedLink> _resolveByResponse(
    Uri uri, {
    String? referer,
    int depth = 0,
    Set<String>? visited,
  }) async {
    final response = await _downloader.open(uri, referer: referer);
    final contentType =
        response.headers.contentType?.mimeType.toLowerCase() ?? '';

    if (response.statusCode >= 400) {
      await response.drain<void>();
      throw DownloadException('The server returned ${response.statusCode}.');
    }

    if (contentType.contains('mpegurl')) {
      return _resolveHlsText(uri, await _readText(response), referer: referer);
    }
    if (contentType.contains('dash')) {
      return _resolveDashText(uri, await _readText(response), referer: referer);
    }
    final isMedia =
        contentType.startsWith('video/') ||
        contentType.startsWith('audio/') ||
        contentType == 'application/octet-stream' ||
        contentType == 'binary/octet-stream' ||
        contentType == 'application/mp4';
    if (isMedia) {
      final length = response.contentLength > 0 ? response.contentLength : null;
      await response.drain<void>();
      return _directResult(
        uri,
        sizeBytes: length,
        contentType: contentType,
        referer: referer,
      );
    }

    final text = await _readText(response);
    if (looksLikeHls(text)) return _resolveHlsText(uri, text, referer: referer);
    if (looksLikeDash(text)) {
      return _resolveDashText(uri, text, referer: referer);
    }
    if (contentType.contains('html') ||
        text.contains('<html') ||
        text.contains('<video') ||
        text.contains('<source')) {
      return _resolvePage(uri, text, depth: depth, visited: visited);
    }
    return _directResult(
      uri,
      sizeBytes: null,
      contentType: contentType,
      referer: referer,
    );
  }

  Future<String> _readText(
    HttpClientResponse response, {
    int maxBytes = _maxTextBytes,
  }) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length >= maxBytes) break;
    }
    final end = bytes.length > maxBytes ? maxBytes : bytes.length;
    return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
  }

  // ---------------------------------------------------------------------------
  // Direct files

  Future<ResolvedLink> _resolveDirect(Uri uri) async {
    final size = await _downloader.probeSize(uri);
    return _directResult(uri, sizeBytes: size);
  }

  ResolvedLink _directResult(
    Uri uri, {
    int? sizeBytes,
    String? contentType,
    String? referer,
  }) {
    final extension = _extension(uri.path);
    final kind = _kindFor(extension, contentType);
    return ResolvedLink(
      title: _fileName(uri),
      variants: [
        DownloadVariant(
          label: kind == MediaKind.audio ? 'Audio file' : 'Video file',
          url: uri,
          referer: referer,
          kind: kind,
          outputExtension: _directOutputExtension(extension, contentType, kind),
          sizeBytes: sizeBytes,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HLS

  Future<ResolvedLink> _resolveHls(Uri uri, {String? referer}) async {
    final text = await _downloader.fetchText(uri, referer: referer);
    return _resolveHlsText(uri, text, referer: referer);
  }

  Future<ResolvedLink> _resolveHlsText(
    Uri uri,
    String text, {
    String? referer,
  }) async {
    if (hlsHasMasterVariants(text)) {
      final renditions = parseHlsMaster(text, uri);
      final variants = <DownloadVariant>[];
      for (final rendition in renditions) {
        final variant = await _hlsVariant(rendition, referer: referer);
        if (variant != null) variants.add(variant);
      }
      if (variants.isEmpty) {
        throw DownloadException(
          'None of the stream\'s qualities could be read.',
        );
      }
      _sortByQuality(variants);
      return ResolvedLink(
        title: _fileName(uri),
        variants: variants,
        note: 'Found ${variants.length} quality option(s).',
      );
    }
    if (!looksLikeHls(text)) {
      throw DownloadException('That link is not an HLS playlist.');
    }
    final media = parseHlsMedia(text, uri);
    if (media.plan.isEmpty) {
      throw DownloadException('The playlist contained no segments.');
    }
    return ResolvedLink(
      title: _fileName(uri),
      variants: [
        _hlsVariantFromMedia(media, uri, rendition: null, referer: referer),
      ],
    );
  }

  Future<DownloadVariant?> _hlsVariant(
    HlsRendition rendition, {
    String? referer,
  }) async {
    try {
      final text = await _downloader.fetchText(
        rendition.uri,
        maxBytes: 1024 * 1024,
        referer: referer,
      );
      if (!looksLikeHls(text)) return null;
      final media = parseHlsMedia(text, rendition.uri);
      if (media.plan.isEmpty) return null;
      return _hlsVariantFromMedia(
        media,
        rendition.uri,
        rendition: rendition,
        referer: referer,
      );
    } on Exception {
      return null;
    }
  }

  DownloadVariant _hlsVariantFromMedia(
    HlsMedia media,
    Uri uri, {
    required HlsRendition? rendition,
    String? referer,
  }) {
    final width = rendition?.width;
    final height = rendition?.height;
    final bandwidth = rendition?.bandwidthBps;
    final codecs = rendition?.codecs;
    final isAudio = _hlsIsAudio(codecs, width, height);
    final size = _estimateSize(bandwidth, media.duration);
    return DownloadVariant(
      label: _variantLabel(
        width: width,
        height: height,
        bandwidthBps: bandwidth,
        audio: isAudio,
      ),
      url: uri,
      referer: referer,
      kind: isAudio ? MediaKind.audio : MediaKind.video,
      outputExtension: _hlsOutputExtension(media.plan, isAudio),
      width: width,
      height: height,
      bandwidthBps: bandwidth,
      sizeBytes: size,
      sizeIsEstimate: size != null,
      stream: StreamKind.hls,
      codecs: codecs,
      plan: media.plan,
    );
  }

  // ---------------------------------------------------------------------------
  // DASH

  Future<ResolvedLink> _resolveDash(Uri uri, {String? referer}) async {
    final text = await _downloader.fetchText(uri, referer: referer);
    if (!looksLikeDash(text)) {
      throw DownloadException('That link is not a DASH manifest.');
    }
    return _resolveDashText(uri, text, referer: referer);
  }

  Future<ResolvedLink> _resolveDashText(
    Uri uri,
    String text, {
    String? referer,
  }) async {
    final manifest = parseDash(text, uri);
    final usable = manifest.representations
        .where((r) => !r.plan.isEmpty)
        .toList();
    if (usable.isEmpty) {
      throw DownloadException(
        'This DASH stream uses a layout the app cannot download yet.',
      );
    }
    final variants = <DownloadVariant>[];
    for (final rep in usable) {
      final size = _estimateSize(rep.bandwidthBps, manifest.duration);
      variants.add(
        DownloadVariant(
          label: _variantLabel(
            width: rep.width,
            height: rep.height,
            bandwidthBps: rep.bandwidthBps,
            audio: rep.isAudio,
          ),
          url: uri,
          referer: referer,
          kind: rep.isAudio ? MediaKind.audio : MediaKind.video,
          outputExtension: rep.isAudio ? 'm4a' : 'mp4',
          width: rep.width,
          height: rep.height,
          bandwidthBps: rep.bandwidthBps,
          sizeBytes: size,
          sizeIsEstimate: size != null,
          stream: StreamKind.dash,
          codecs: rep.codecs,
          plan: rep.plan,
        ),
      );
    }
    _sortByQuality(variants);
    return ResolvedLink(
      title: _fileName(uri),
      variants: variants,
      note: 'Found ${variants.length} quality option(s).',
    );
  }

  // ---------------------------------------------------------------------------
  // Web pages

  Future<ResolvedLink> _resolvePage(
    Uri pageUrl,
    String html, {
    int depth = 0,
    Set<String>? visited,
  }) async {
    final seenPages = visited ?? <String>{};
    if (!seenPages.add(pageUrl.toString())) {
      throw DownloadException('A player page linked back to itself.');
    }

    // SpankBang exposes a signed progressive MP4 URL in its player markup.
    // If its page is reachable through the user's browser/session, use that
    // URL directly and retain the page Referer for the later media request.
    if (_isSpankBangHost(pageUrl.host)) {
      final spankBangSources = await _findSpankBangSources(pageUrl, html);
      if (spankBangSources.isNotEmpty) {
        return ResolvedLink(
          title: _pageTitle(html) ?? _fileName(pageUrl),
          variants: spankBangSources,
          note: 'Found ${spankBangSources.length} SpankBang video option(s).',
        );
      }
    }

    // The shared resolver path cannot reliably fetch embeds blocked by the
    // browser's cross-origin policy. Prefer the on-device extractor for those
    // pages, but keep the native source resolution below as a fallback.
    // (Extractor selection itself is done by DownloadController.)

    if (pageUrl.host == 'javtiful.com' ||
        pageUrl.host.endsWith('.javtiful.com')) {
      try {
        final siteSources = await _resolveJavtifulSources(pageUrl, html);
        if (siteSources.isNotEmpty) {
          return ResolvedLink(
            title: _pageTitle(html) ?? _fileName(pageUrl),
            variants: siteSources,
            note: 'Found ${siteSources.length} playable source(s).',
          );
        }
      } on Exception {
        // Continue with ordinary markup if the site's player API is down.
      }
    }

    final variants = <DownloadVariant>[];
    final sourceTexts = [html, ..._unpackPackedPlayerScripts(html)];
    final mediaCandidates = <Uri>{
      for (final sourceText in sourceTexts)
        ..._findMediaUrls(pageUrl, sourceText),
    };
    // Progressive MP4 sources in ePorner markup are the actual player files.
    // Resolve these directly and skip thumbnail, preview, and ad candidates
    // that otherwise make the page crawl slow or yield unrelated clips.
    final eporner =
        pageUrl.host == 'eporner.com' || pageUrl.host.endsWith('.eporner.com');
    final candidates =
        (eporner
                ? mediaCandidates.where(
                    (uri) =>
                        uri.host == 'gvideo.eporner.com' &&
                        _extension(uri.path) == 'mp4',
                  )
                : mediaCandidates)
            .take(_maxPageCandidates);
    for (final candidate in candidates) {
      try {
        variants.addAll(
          (await _resolveByResponse(
            candidate,
            referer: pageUrl.toString(),
            depth: depth + 1,
            visited: seenPages,
          )).variants,
        );
      } on Exception {
        // Skip candidates that fail; keep whatever else worked.
      }
    }

    // Many pages keep the player in a separate iframe, whose HTML contains
    // the actual manifest or file URL. Follow only a small, bounded number of
    // HTTPS embeds and cap nesting to avoid loops and unrelated page crawling.
    if (depth < _maxEmbedDepth) {
      var embedded = 0;
      final frames = _findEmbeddedPages(pageUrl, html).toList();
      // Jav Guru exposes several unrelated promo iframe configs. The video
      // player config is derived from its own data attributes; process it
      // first and do not probe the promo frames after it succeeds.
      if (pageUrl.host == 'jav.guru' || pageUrl.host.endsWith('.jav.guru')) {
        final player = _javGuruPlayerPage(
          pageUrl,
          _normalizeEmbeddedText(html),
        );
        if (player != null) {
          frames
            ..remove(player)
            ..insert(0, player);
        }
      }
      for (final frame in frames) {
        if (embedded++ >= _maxEmbeddedPages) break;
        if (seenPages.contains(frame.toString())) continue;
        try {
          final nested = await _resolveByResponse(
            frame,
            depth: depth + 1,
            visited: seenPages,
            referer: pageUrl.toString(),
          );
          variants.addAll(nested.variants);
          if ((pageUrl.host == 'jav.guru' ||
                  pageUrl.host.endsWith('.jav.guru')) &&
              variants.isNotEmpty) {
            break;
          }
        } on Exception {
          // A blocked or non-video embed must not discard other candidates.
        }
      }
    }

    if (variants.isEmpty) {
      throw DownloadException(
        'No downloadable video was found in the page or its player embeds. '
        'The player may require scripts, a signed-in session, or DRM.',
      );
    }
    final uniqueVariants = <String, DownloadVariant>{};
    for (final variant in variants) {
      uniqueVariants.putIfAbsent(
        '${variant.url}|${variant.height}|${variant.label}',
        () => variant,
      );
    }
    final resultVariants = uniqueVariants.values.toList();
    _sortByQuality(resultVariants);
    return ResolvedLink(
      title: _pageTitle(html) ?? _fileName(pageUrl),
      variants: resultVariants,
      note: 'Found ${resultVariants.length} video option(s) on the page.',
    );
  }

  List<Uri> _findMediaUrls(Uri pageUrl, String html) {
    // Player configs commonly use JSON escapes and HTML entities.
    final normalized = _normalizeEmbeddedText(html);
    final found = <String>{};
    for (final pattern in [
      RegExp(
        r'''<(?:video|source)[^>]*\s(?:src|data-src|data-file|data-hls)=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta\b[^>]*(?:property|name)=["'](?:og:video(?::url)?|twitter:player:stream)["'][^>]*content=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta\b[^>]*content=["']([^"']+)["'][^>]*(?:property|name)=["'](?:og:video(?::url)?|twitter:player:stream)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''["']contentUrl["']\s*:\s*["']([^"']+)["']''',
        caseSensitive: false,
      ),
    ]) {
      for (final m in pattern.allMatches(normalized)) {
        found.add(m.group(1)!);
      }
    }
    final urlPattern = RegExp(
      r'''(?:https?:)?//[^\s"'<>\\)]+?\.(?:m3u8|mpd|mp4|m4v|mov|webm|mkv|mp3|m4a|aac)(?:\?[^\s"'<>\\)]*)?''',
      caseSensitive: false,
    );
    for (final m in urlPattern.allMatches(normalized)) {
      found.add(m.group(0)!);
    }
    final quotedMediaPath = RegExp(
      r'''["']([^"'\s<>]+?\.(?:m3u8|mpd|mp4|m4v|mov|webm|mkv|mp3|m4a|aac)(?:\?[^"']*)?)["']''',
      caseSensitive: false,
    );
    for (final m in quotedMediaPath.allMatches(normalized)) {
      found.add(m.group(1)!);
    }
    // JWPlayer, Video.js, and custom players often keep their source in a JS
    // object rather than in a video/source element.
    final configPattern = RegExp(
      r'''(?:file|src|source|hls|dash|manifest|contentUrl|videoUrl|streamUrl)\s*[:=]\s*["']([^"']+)["']''',
      caseSensitive: false,
    );
    for (final m in configPattern.allMatches(normalized)) {
      found.add(m.group(1)!);
    }

    const priority = {
      'm3u8': 0,
      'mpd': 1,
      'mp4': 2,
      'm4v': 3,
      'webm': 4,
      'mov': 5,
      'mkv': 6,
    };
    final uris = <Uri>[];
    for (final raw in found) {
      if (raw.startsWith('blob:') || raw.startsWith('data:')) continue;
      final uri = Uri.tryParse(raw);
      if (uri == null) continue;
      final resolved = uri.isAbsolute ? uri : pageUrl.resolve(raw);
      // Only secure media can be fetched (Android blocks cleartext).
      if (resolved.scheme != 'https') continue;
      final extension = _extension(resolved.path);
      if (!_directExtensions.contains(extension) &&
          extension != 'm3u8' &&
          extension != 'mpd') {
        continue;
      }
      uris.add(resolved);
    }
    uris.sort(
      (a, b) => (priority[_extension(a.path)] ?? 99).compareTo(
        priority[_extension(b.path)] ?? 99,
      ),
    );
    final seen = <String>{};
    return [
      for (final u in uris)
        if (seen.add(u.toString())) u,
    ];
  }

  bool _isSpankBangHost(String host) =>
      host == 'spankbang.com' ||
      host.endsWith('.spankbang.com') ||
      host == 'spankbang.party' ||
      host.endsWith('.spankbang.party');

  Future<List<DownloadVariant>> _findSpankBangSources(
    Uri pageUrl,
    String html,
  ) async {
    final normalized = _normalizeEmbeddedText(html)
        .replaceAll(r'\u002c', ',')
        .replaceAll(r'\u0026', '&');
    final pattern = RegExp(
      r'''https?://vdownload-[^/\s"'<>\\]+\.sb-cd\.com/[^\s"'<>\\]+?\.mp4(?:\?[^\s"'<>\\]*)?''',
      caseSensitive: false,
    );
    final variants = <DownloadVariant>[];
    final seen = <String>{};
    for (final match in pattern.allMatches(normalized)) {
      final raw = match.group(0)!.replaceAll(r'\_', '_');
      final uri = Uri.tryParse(raw);
      if (uri == null || uri.scheme != 'https' || !seen.add(uri.toString())) {
        continue;
      }
      final size = await _downloader.probeSize(
        uri,
        referer: pageUrl.toString(),
      );
      variants.add(
        DownloadVariant(
          label: _spankBangQuality(uri) ?? 'Video file',
          url: uri,
          referer: pageUrl.toString(),
          kind: MediaKind.video,
          outputExtension: 'mp4',
          height: _spankBangHeight(uri),
          sizeBytes: size,
        ),
      );
    }
    _sortByQuality(variants);
    return variants;
  }

  int? _spankBangHeight(Uri uri) {
    final match = RegExp(
      r'-(\d{3,4})p\.mp4',
      caseSensitive: false,
    ).firstMatch(uri.path);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String? _spankBangQuality(Uri uri) {
    final height = _spankBangHeight(uri);
    return height == null ? null : '${height}p';
  }

  List<Uri> _findEmbeddedPages(Uri pageUrl, String html) {
    final normalized = _normalizeEmbeddedText(html);
    final found = <Uri>{};

    // Jav Guru builds its public JW Player iframe URL when the user presses
    // the page's Play button. Reproduce that URL construction from the page's
    // own config and data attributes; do not execute the remote script.
    if (pageUrl.host == 'jav.guru' || pageUrl.host.endsWith('.jav.guru')) {
      final player = _javGuruPlayerPage(pageUrl, normalized);
      if (player != null) found.add(player);
    }

    final pagePatterns = [
      RegExp(
        r'''<iframe\b[^>]*\b(?:src|data-src)=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta\b[^>]*itemprop=["']embedurl["'][^>]*content=["']([^"']+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta\b[^>]*content=["']([^"']+)["'][^>]*itemprop=["']embedurl["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''["']embedUrl["']\s*:\s*["']([^"']+)["']''',
        caseSensitive: false,
      ),
    ];
    for (final pattern in pagePatterns) {
      for (final match in pattern.allMatches(normalized)) {
        _addHttpsPage(pageUrl, match.group(1), found);
      }
    }

    // Some WordPress video pages store the player iframe URL as base64 in a
    // small `iframe_url` config object, then create the iframe with JavaScript.
    final encodedPattern = RegExp(
      r'''["']iframe_url["']\s*:\s*["']([A-Za-z0-9_+/=-]+)["']''',
      caseSensitive: false,
    );
    for (final match in encodedPattern.allMatches(normalized)) {
      try {
        final encoded = base64Url.normalize(match.group(1)!);
        final decoded = utf8.decode(base64Url.decode(encoded));
        _addHttpsPage(pageUrl, decoded, found);
      } on FormatException {
        // Ignore unrelated or malformed base64 values.
      }
    }
    return found.toList();
  }

  Uri? _javGuruPlayerPage(Uri pageUrl, String html) {
    final config = RegExp(r'''window\.cfg\s*=\s*\{([\s\S]*?)\};''')
        .firstMatch(html)
        ?.group(1);
    if (config == null) return null;
    String? field(String name) {
      final match = RegExp("(^|[,\\s])$name\\s*:\\s*(?:\"([^\"]+)\"|'([^']+)')")
          .firstMatch(config);
      return match?.group(2) ?? match?.group(3);
    }

    final cid = field('cid');
    final base = field('base');
    final routeType = field('rtype');
    final keysText = RegExp(r'''keys\s*:\s*\[([^\]]+)\]''')
        .firstMatch(config)
        ?.group(1);
    if (cid == null || base == null || routeType == null || keysText == null) {
      return null;
    }
    final keyPattern = RegExp(r'''["']([^"']+)["']''');
    final keys = keyPattern
        .allMatches(keysText)
        .map((m) => m.group(1)!)
        .toList();
    if (keys.length != 3) return null;
    final tagPattern = RegExp(
      "<[^>]*\\bid=(?:\"${RegExp.escape(cid)}\"|'${RegExp.escape(cid)}')[^>]*>",
      caseSensitive: false,
    );
    final tag = tagPattern.firstMatch(html)?.group(0);
    if (tag == null) return null;
    final values = <String>[];
    for (final key in keys) {
      final attrPattern = RegExp(
        "${RegExp.escape(key)}\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')",
        caseSensitive: false,
      );
      final match = attrPattern.firstMatch(tag);
      final value = match?.group(1) ?? match?.group(2);
      if (value == null || value.isEmpty) return null;
      values.add(value);
    }
    final token = values.join().split('').reversed.join();
    final baseUri = Uri.tryParse(base);
    if (baseUri == null || baseUri.scheme != 'https') return null;
    return baseUri.replace(
      queryParameters: {...baseUri.queryParameters, '${routeType}r': token},
    );
  }

  /// Unpacks the static string form of Dean Edwards' Packer, used by the
  /// public Jav Guru JW Player page. The output is text-parsed for media URLs;
  /// no remote JavaScript is run.
  List<String> _unpackPackedPlayerScripts(String html) {
    final pattern = RegExp(
      r'''eval\(function\(p,a,c,k,e,d\)[\s\S]*?\}\('((?:\\.|[^'\\])*)'\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*'((?:\\.|[^'\\])*)'\.split\('\|'\)''',
    );
    final unpacked = <String>[];
    for (final match in pattern.allMatches(html)) {
      try {
        final packed = _decodeJsString(match.group(1)!);
        final radix = int.parse(match.group(2)!);
        final count = int.parse(match.group(3)!);
        final dictionary = _decodeJsString(match.group(4)!).split('|');
        if (radix < 2 || radix > 62 || count > 20000) continue;
        var decoded = packed;
        for (var i = count - 1; i >= 0; i--) {
          if (i >= dictionary.length || dictionary[i].isEmpty) continue;
          decoded = decoded.replaceAll(
            RegExp('\\b${RegExp.escape(_radixToken(i, radix))}\\b'),
            dictionary[i],
          );
        }
        unpacked.add(decoded);
      } on FormatException {
        // Ignore a page script that does not match the standard Packer form.
      }
    }
    return unpacked;
  }

  String _decodeJsString(String value) {
    final out = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char != '\\' || i + 1 >= value.length) {
        out.write(char);
        continue;
      }
      final escaped = value[++i];
      switch (escaped) {
        case 'n':
          out.write('\n');
        case 'r':
          out.write('\r');
        case 't':
          out.write('\t');
        case 'b':
          out.write('\b');
        case 'f':
          out.write('\f');
        case 'u':
          if (i + 4 < value.length) {
            final codeUnit = int.tryParse(
              value.substring(i + 1, i + 5),
              radix: 16,
            );
            if (codeUnit != null) {
              out.writeCharCode(codeUnit);
              i += 4;
            } else {
              out.write(escaped);
            }
          }
        default:
          out.write(escaped);
      }
    }
    return out.toString();
  }

  String _radixToken(int value, int radix) {
    const digits =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (value == 0) return '0';
    var current = value;
    var token = '';
    while (current > 0) {
      token = digits[current % radix] + token;
      current ~/= radix;
    }
    return token;
  }

  Future<List<DownloadVariant>> _resolveJavtifulSources(
    Uri pageUrl,
    String html,
  ) async {
    final script = RegExp(
      r'''<script\b[^>]*\bid=["']watch-config["'][^>]*>([\s\S]*?)</script>''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    if (script == null) return const [];

    final config = jsonDecode(script);
    if (config is! Map) return const [];
    final playback = config['playback'];
    if (playback is! Map) return const [];
    final endpointRaw = playback['endpoint'];
    final ticket = playback['ticket'];
    if (endpointRaw is! String || ticket is! String || ticket.isEmpty) {
      return const [];
    }

    final endpoint = pageUrl.resolve(endpointRaw);
    final responseText = await _downloader.postFormText(
      endpoint,
      {'ticket': ticket},
      referer: pageUrl.toString(),
      origin: '${pageUrl.scheme}://${pageUrl.authority}',
      headers: const {'X-Requested-With': 'XMLHttpRequest'},
    );
    final response = jsonDecode(responseText);
    if (response is! Map || response['success'] != true) return const [];
    final sources = response['sources'];
    if (sources is! List) return const [];

    final variants = <DownloadVariant>[];
    for (final raw in sources.whereType<Map>()) {
      final src = raw['src'];
      if (src is! String || src.isEmpty) continue;
      final type = raw['type'] is String ? raw['type'] as String : 'video/mp4';
      final height = (raw['size'] as num?)?.toInt();
      final label = raw['label'] is String
          ? raw['label'] as String
          : (height == null ? 'Video' : '${height}p');
      final media = await _resolveJavtifulMedia(
        pageUrl,
        src,
        type: type,
        label: label,
        height: height,
      );
      if (media != null) variants.addAll(media);

      final fallback = raw['fallbackSrc'];
      if (fallback is String && fallback.isNotEmpty) {
        final backup = await _resolveJavtifulMedia(
          pageUrl,
          fallback,
          type: 'video/mp4',
          label: height == null ? 'MP4 fallback' : '${height}p MP4 fallback',
          height: height,
        );
        if (backup != null) variants.addAll(backup);
      }
    }
    return variants;
  }

  Future<List<DownloadVariant>?> _resolveJavtifulMedia(
    Uri pageUrl,
    String rawUrl, {
    required String type,
    required String label,
    required int? height,
  }) async {
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) return null;
    final uri = parsed.isAbsolute ? parsed : pageUrl.resolveUri(parsed);
    if (uri.scheme != 'https') return null;
    final extension = _extension(uri.path);
    if (extension == 'm3u8' || type.toLowerCase().contains('mpegurl')) {
      return (await _resolveHls(uri, referer: pageUrl.toString())).variants;
    }
    if (extension == 'mpd' || type.toLowerCase().contains('dash')) {
      return (await _resolveDash(uri, referer: pageUrl.toString())).variants;
    }

    final size = await _downloader.probeSize(uri, referer: pageUrl.toString());
    return [
      DownloadVariant(
        label: label,
        url: uri,
        referer: pageUrl.toString(),
        kind: MediaKind.video,
        outputExtension: _directOutputExtension(
          extension,
          type,
          MediaKind.video,
        ),
        height: height,
        sizeBytes: size,
      ),
    ];
  }

  void _addHttpsPage(Uri base, String? raw, Set<Uri> found) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || value.startsWith('javascript:')) {
      return;
    }
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    final resolved = uri.isAbsolute ? uri : base.resolveUri(uri);
    if (resolved.scheme == 'https' && resolved.host.isNotEmpty) {
      found.add(resolved);
    }
  }

  String _normalizeEmbeddedText(String text) => text
      .replaceAll(r'\/', '/')
      .replaceAll(r'\u0026', '&')
      .replaceAll(r'\u003d', '=')
      .replaceAll(r'\u003a', ':')
      .replaceAll(r'\u002f', '/')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#x2F;', '/')
      .replaceAll('&#x2f;', '/')
      .replaceAll('&#47;', '/');

  String? _pageTitle(String html) {
    final m = RegExp(
      r'<title[^>]*>([^<]*)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    final title = m?.group(1)?.trim();
    return (title == null || title.isEmpty) ? null : title;
  }

  // ---------------------------------------------------------------------------
  // Shared helpers

  void _sortByQuality(List<DownloadVariant> variants) {
    variants.sort((a, b) {
      final byHeight = (b.height ?? 0).compareTo(a.height ?? 0);
      if (byHeight != 0) return byHeight;
      return (b.bandwidthBps ?? 0).compareTo(a.bandwidthBps ?? 0);
    });
  }

  int? _estimateSize(int? bandwidthBps, Duration? duration) {
    if (bandwidthBps == null || duration == null) return null;
    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0) return null;
    return (bandwidthBps / 8 * seconds).round();
  }

  bool _hlsIsAudio(String? codecs, int? width, int? height) {
    if (width != null || height != null) return false;
    final value = codecs?.toLowerCase();
    if (value == null) return false;
    const videoCodecs = [
      'avc',
      'hvc',
      'hev',
      'vp8',
      'vp9',
      'av01',
      'dvhe',
      'dvh1',
    ];
    return !videoCodecs.any(value.contains);
  }

  String _hlsOutputExtension(SegmentPlan plan, bool isAudio) {
    final samples = <String>[
      if (plan.init != null) _extension(plan.init!.path),
      if (plan.segments.isNotEmpty) _extension(plan.segments.first.path),
    ];
    for (final extension in samples) {
      if (extension == 'mp4' || extension == 'm4s') {
        return isAudio ? 'm4a' : 'mp4';
      }
      if (extension == 'aac') return 'aac';
      if (extension == 'mp3') return 'mp3';
    }
    return isAudio ? 'aac' : 'ts';
  }

  String _variantLabel({
    required int? width,
    required int? height,
    required int? bandwidthBps,
    required bool audio,
  }) {
    final parts = <String>[];
    if (audio) {
      parts.add('Audio');
    } else if (height != null) {
      parts.add('${height}p');
    } else if (width != null) {
      parts.add('${width}w');
    } else {
      parts.add('Stream');
    }
    if (bandwidthBps != null) {
      parts.add('${(bandwidthBps / 1000000).toStringAsFixed(1)} Mbps');
    }
    return parts.join(' · ');
  }

  MediaKind _kindFor(String extension, String? contentType) {
    final type = contentType ?? '';
    if (type.startsWith('audio/') || _audioExtensions.contains(extension)) {
      return MediaKind.audio;
    }
    return MediaKind.video;
  }

  String _directOutputExtension(
    String extension,
    String? contentType,
    MediaKind kind,
  ) {
    if (extension.isNotEmpty && extension != 'm3u8' && extension != 'mpd') {
      if (kind == MediaKind.audio && !_audioExtensions.contains(extension)) {
        return 'm4a';
      }
      return extension;
    }
    final type = contentType ?? '';
    if (type.contains('audio') && type.contains('mpeg')) return 'mp3';
    if (type.contains('audio')) return 'm4a';
    if (type.contains('webm')) return 'webm';
    return kind == MediaKind.audio ? 'm4a' : 'mp4';
  }

  String _extension(String path) {
    final slash = path.lastIndexOf('/');
    final dot = path.lastIndexOf('.');
    if (dot <= slash || dot < 0 || dot == path.length - 1) return '';
    final extension = path.substring(dot + 1).toLowerCase();
    return extension.length <= 5 ? extension : '';
  }

  String _fileName(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return uri.host.isEmpty ? 'download' : uri.host;
    try {
      final last = Uri.decodeComponent(segments.last).trim();
      return last.isEmpty ? 'download' : last;
    } on FormatException {
      return segments.last;
    }
  }
}
