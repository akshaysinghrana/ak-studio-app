import 'dart:io';

import '../../playback/domain/media_source.dart';

/// Rules for what may be downloaded and how files are named (ADR 0004).
abstract final class DownloadRules {
  /// YouTube's terms forbid downloading through an API client, so links to
  /// YouTube or its video hosts are always refused.
  static const _blockedHosts = [
    'youtube.com',
    'youtu.be',
    'youtube-nocookie.com',
    'googlevideo.com',
    'ytimg.com',
  ];

  static bool isBlockedHost(String host) {
    final h = host.toLowerCase();
    return _blockedHosts.any((b) => h == b || h.endsWith('.$b'));
  }

  /// Why [input] cannot be downloaded as a direct link, or null if it can.
  static String? validateUrl(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      return 'Enter a full link starting with https://';
    }
    if (isBlockedHost(uri.host)) {
      return 'YouTube videos cannot be downloaded. Watch them in Discover → '
          'YouTube instead.';
    }
    return null;
  }

  /// MP3 or MP4 from a MIME type and/or file name; null if unsupported.
  static MediaKind? kindFor({String? mimeType, String? fileName}) {
    final mime = mimeType?.split(';').first.trim().toLowerCase();
    if (mime == 'audio/mpeg' || mime == 'audio/mp3') return MediaKind.audio;
    if (mime == 'video/mp4') return MediaKind.video;
    return fileName == null ? null : MediaSource.kindForFileName(fileName);
  }

  static String extensionFor(MediaKind kind) =>
      kind == MediaKind.audio ? 'mp3' : 'mp4';

  /// A safe file name like `Artist - Title.mp3`.
  static String fileName(String title, MediaKind kind, {String? artist}) {
    final base = [
      if (artist != null && artist.trim().isNotEmpty) artist.trim(),
      title.trim(),
    ].join(' - ');
    var clean = base
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) clean = 'download';
    if (clean.length > 120) clean = clean.substring(0, 120).trim();
    return '$clean.${extensionFor(kind)}';
  }

  /// The last path segment of [url] without its extension, for titles.
  static String titleFromUrl(Uri url) {
    final last = url.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    if (last == null) return url.host;
    final decoded = Uri.decodeComponent(last);
    final dot = decoded.lastIndexOf('.');
    return dot > 0 ? decoded.substring(0, dot) : decoded;
  }

  /// True when [header] (the first bytes of a file) looks like [kind]:
  /// an ID3 tag or MPEG audio frame sync for MP3, an `ftyp` box for MP4.
  static bool looksLike(List<int> header, MediaKind kind) {
    if (kind == MediaKind.audio) {
      if (header.length >= 3 &&
          header[0] == 0x49 &&
          header[1] == 0x44 &&
          header[2] == 0x33) {
        return true; // "ID3"
      }
      return header.length >= 2 &&
          header[0] == 0xFF &&
          (header[1] & 0xE0) == 0xE0;
    }
    return header.length >= 8 &&
        header[4] == 0x66 &&
        header[5] == 0x74 &&
        header[6] == 0x79 &&
        header[7] == 0x70; // "ftyp"
  }

  /// Checks a finished download before it is added to the library.
  static Future<String?> validateFile(File file, MediaKind kind) async {
    if (!await file.exists() || await file.length() == 0) {
      return 'The download is empty.';
    }
    final raf = await file.open();
    try {
      final header = await raf.read(16);
      if (!looksLike(header, kind)) {
        return kind == MediaKind.audio
            ? 'The file is not an MP3.'
            : 'The file is not an MP4 video.';
      }
    } finally {
      await raf.close();
    }
    return null;
  }

  /// MediaStore relative folder of a shared-storage path, e.g.
  /// `/storage/emulated/0/Music/AS Media/a.mp3` → `Music/AS Media/`.
  static String? relativeFolder(String path) {
    final m =
        RegExp(r'^/storage/[^/]+/\d+/(.+/)[^/]+$').firstMatch(path) ??
        RegExp(r'^/storage/[^/]+/(.+/)[^/]+$').firstMatch(path) ??
        RegExp(r'^/sdcard/(.+/)[^/]+$').firstMatch(path);
    return m?.group(1);
  }
}
