import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:video_music_app/core/net/json_client.dart';
import 'package:video_music_app/features/youtube/data/youtube_api.dart';

Map<String, dynamic> video(String id, String duration) => {
  'id': id,
  'snippet': {
    'title': 'Title &amp; more $id',
    'channelTitle': 'Channel',
    'publishedAt': '2026-10-01T00:00:00Z',
    'thumbnails': {
      'high': {'url': 'https://i.ytimg.com/$id.jpg'},
    },
  },
  'contentDetails': {'duration': duration},
  'statistics': {'viewCount': '12345'},
};

void main() {
  test('ISO 8601 durations', () {
    expect(
      YouTubeApi.parseIsoDuration('PT1H2M3S'),
      const Duration(hours: 1, minutes: 2, seconds: 3),
    );
    expect(YouTubeApi.parseIsoDuration('PT45S'), const Duration(seconds: 45));
    expect(YouTubeApi.parseIsoDuration('P0D'), isNull); // live
    expect(YouTubeApi.parseIsoDuration('nonsense'), isNull);
  });

  test(
    'search keeps result order, adds details and sends app headers',
    () async {
      final requests = <http.Request>[];
      final api = YouTubeApi(
        JsonClient(
          MockClient((req) async {
            requests.add(req);
            if (req.url.path.endsWith('/search')) {
              return http.Response(
                jsonEncode({
                  'items': [
                    {
                      'id': {'videoId': 'b'},
                    },
                    {
                      'id': {'videoId': 'a'},
                    },
                  ],
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'items': [video('a', 'PT3M'), video('b', 'PT4M5S')],
              }),
              200,
            );
          }),
        ),
        apiKey: 'KEY',
        androidPackage: 'com.example',
        androidCertSha1: 'ABCD',
      );
      final results = await api.search('lofi', regionCode: 'IN');
      expect(results.map((v) => v.id), ['b', 'a']);
      expect(results.first.title, 'Title & more b');
      expect(results.first.duration, const Duration(minutes: 4, seconds: 5));
      expect(results.first.viewCount, 12345);
      final search = requests.first;
      expect(search.url.queryParameters['videoEmbeddable'], 'true');
      expect(search.url.queryParameters['type'], 'video');
      expect(search.url.queryParameters['regionCode'], 'IN');
      expect(search.headers['X-Android-Package'], 'com.example');
      expect(search.headers['X-Android-Cert'], 'ABCD');
    },
  );

  test('quota and key errors are explained', () async {
    YouTubeApi api(int status, String reason) => YouTubeApi(
      JsonClient(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'errors': [
                  {'reason': reason},
                ],
              },
            }),
            status,
          ),
        ),
      ),
      apiKey: 'KEY',
    );
    await expectLater(
      api(403, 'quotaExceeded').popularMusic(),
      throwsA(
        isA<OnlineFailure>().having((e) => e.message, 'm', contains('quota')),
      ),
    );
    await expectLater(
      api(400, 'keyInvalid').popularMusic(),
      throwsA(
        isA<OnlineFailure>().having((e) => e.message, 'm', contains('key')),
      ),
    );
  });
}
