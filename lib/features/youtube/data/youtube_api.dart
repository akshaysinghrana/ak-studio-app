import '../../../core/net/json_client.dart';

class YouTubeVideo {
  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.channel,
    this.thumbnailUrl,
    this.publishedAt,
    this.duration,
    this.viewCount,
  });

  final String id;
  final String title;
  final String channel;
  final String? thumbnailUrl;
  final DateTime? publishedAt;
  final Duration? duration;
  final int? viewCount;
}

/// YouTube Data API v3: search and the music chart (ADR 0004). Results are
/// shown and played only in the official embedded player; nothing is
/// downloaded or extracted.
class YouTubeApi {
  YouTubeApi(
    this._client, {
    required this.apiKey,
    this.androidPackage,
    this.androidCertSha1,
  });

  final JsonClient _client;
  final String apiKey;

  /// Sent so a key restricted to this Android app is accepted.
  final String? androidPackage;
  final String? androidCertSha1;

  Map<String, String> get _headers => {
    'X-Android-Package': ?androidPackage,
    'X-Android-Cert': ?androidCertSha1,
  };

  Uri _uri(String path, Map<String, String> query) => Uri.https(
    'www.googleapis.com',
    '/youtube/v3/$path',
    {...query, 'key': apiKey},
  );

  static String describeError(int status, Map<String, dynamic>? body) {
    final error = body?['error'];
    final reasons = <String>{
      if (error is Map && error['errors'] is List)
        for (final e in error['errors'] as List)
          if (e is Map && e['reason'] is String) e['reason'] as String,
    };
    if (reasons.contains('quotaExceeded') ||
        reasons.contains('dailyLimitExceeded')) {
      return 'The YouTube API key has used its daily quota. Try again '
          'tomorrow.';
    }
    if (reasons.contains('keyInvalid') ||
        reasons.contains('badRequest') && status == 400) {
      return 'YouTube rejected the API key. Check it in Settings → Online '
          'sources.';
    }
    if (reasons.contains('accessNotConfigured') ||
        reasons.contains('forbidden') ||
        reasons.contains('ipRefererBlocked') ||
        status == 403) {
      return 'YouTube refused the request. Make sure "YouTube Data API v3" '
          'is enabled for the key and that its Android restriction matches '
          'this app.';
    }
    return 'YouTube returned an error ($status).';
  }

  Future<Map<String, dynamic>> _get(String path, Map<String, String> query) =>
      _client.get(
        _uri(path, query),
        headers: _headers,
        describeError: describeError,
      );

  /// Embeddable videos for [query], with durations.
  Future<List<YouTubeVideo>> search(String query, {String? regionCode}) async {
    final body = await _get('search', {
      'part': 'snippet',
      'type': 'video',
      'videoEmbeddable': 'true',
      'maxResults': '20',
      'q': query,
      'regionCode': ?regionCode,
    });
    final ids = [
      for (final item in (body['items'] as List? ?? const []))
        if (item is Map && item['id'] is Map && item['id']['videoId'] is String)
          item['id']['videoId'] as String,
    ];
    return details(ids);
  }

  /// Most popular music videos in [regionCode] (YouTube category 10).
  Future<List<YouTubeVideo>> popularMusic({String? regionCode}) async {
    final body = await _get('videos', {
      'part': 'snippet,contentDetails,statistics',
      'chart': 'mostPopular',
      'videoCategoryId': '10',
      'maxResults': '25',
      'regionCode': ?regionCode,
    });
    return _videos(body);
  }

  /// Full details for [ids], in the same order.
  Future<List<YouTubeVideo>> details(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final body = await _get('videos', {
      'part': 'snippet,contentDetails,statistics',
      'id': ids.join(','),
      'maxResults': '50',
    });
    final byId = {for (final v in _videos(body)) v.id: v};
    return [for (final id in ids) ?byId[id]];
  }

  static List<YouTubeVideo> _videos(Map<String, dynamic> body) => [
    for (final item in (body['items'] as List? ?? const []))
      if (item is Map<String, dynamic>) ?videoFrom(item),
  ];

  static YouTubeVideo? videoFrom(Map<String, dynamic> item) {
    final id = item['id'];
    final snippet = item['snippet'];
    if (id is! String || snippet is! Map) return null;
    final thumbs = snippet['thumbnails'];
    String? thumb;
    if (thumbs is Map) {
      for (final size in ['high', 'medium', 'default']) {
        final t = thumbs[size];
        if (t is Map && t['url'] is String) {
          thumb = t['url'] as String;
          break;
        }
      }
    }
    final details = item['contentDetails'];
    final stats = item['statistics'];
    return YouTubeVideo(
      id: id,
      title: _unescape(snippet['title'] as String? ?? ''),
      channel: _unescape(snippet['channelTitle'] as String? ?? ''),
      thumbnailUrl: thumb,
      publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? ''),
      duration: details is Map
          ? parseIsoDuration(details['duration'] as String?)
          : null,
      viewCount: stats is Map
          ? int.tryParse(stats['viewCount'] as String? ?? '')
          : null,
    );
  }

  /// Parses ISO 8601 durations such as `PT1H2M3S`; null when unknown/live.
  static Duration? parseIsoDuration(String? value) {
    if (value == null) return null;
    final m = RegExp(r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$')
        .firstMatch(value);
    if (m == null) return null;
    int n(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    final d = Duration(days: n(1), hours: n(2), minutes: n(3), seconds: n(4));
    return d == Duration.zero ? null : d;
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
