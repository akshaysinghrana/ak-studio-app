import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:video_music_app/core/net/json_client.dart';
import 'package:video_music_app/features/discover/data/audius_catalog.dart';
import 'package:video_music_app/features/discover/data/jamendo_catalog.dart';
import 'package:video_music_app/features/discover/domain/catalog.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';

Map<String, dynamic> audiusTrack(
  String id, {
  bool streamable = true,
  bool streamGated = false,
  bool downloadable = false,
  bool downloadGated = false,
}) => {
  'id': id,
  'title': 'Song $id',
  'duration': 185,
  'genre': 'Electronic',
  'is_streamable': streamable,
  'is_stream_gated': streamGated,
  'is_downloadable': downloadable,
  'is_download_gated': downloadGated,
  'artwork': {'480x480': 'https://img.example/$id.jpg'},
  'user': {'id': 'u1', 'name': 'Artist'},
};

void main() {
  group('Audius', () {
    late List<Uri> requests;
    AudiusCatalog catalog(Map<String, Object> bodies) {
      requests = [];
      return AudiusCatalog(
        JsonClient(
          MockClient((req) async {
            requests.add(req.url);
            final body = bodies[req.url.path];
            return body == null
                ? http.Response('{}', 404)
                : http.Response(jsonEncode({'data': body}), 200);
          }),
        ),
      );
    }

    test(
      'hides gated and unstreamable tracks; downloads only if allowed',
      () async {
        final c = catalog({
          '/v1/tracks/trending': [
            audiusTrack('a'),
            audiusTrack('b', streamable: false),
            audiusTrack('c', streamGated: true),
            audiusTrack('d', downloadable: true),
            audiusTrack('e', downloadable: true, downloadGated: true),
          ],
        });
        final tracks = await c.trending();
        expect(tracks.map((t) => t.id), ['a', 'd', 'e']);
        expect(tracks[0].canDownload, isFalse);
        expect(tracks[1].canDownload, isTrue);
        expect(tracks[2].canDownload, isFalse);
        expect(requests.single.queryParameters['app_name'], 'AS_Media');
      },
    );

    test('tracks stream through the API and become audio sources', () async {
      final c = catalog({
        '/v1/tracks/trending': [audiusTrack('x')],
      });
      final t = (await c.trending(genre: 'Lo-Fi')).single;
      expect(requests.single.queryParameters['genre'], 'Lo-Fi');
      expect(
        t.streamUrl,
        'https://api.audius.co/v1/tracks/x/stream?app_name=AS_Media',
      );
      expect(t.duration, const Duration(minutes: 3, seconds: 5));
      final media = t.toMediaSource();
      expect(media.id, 'audius:x');
      expect(media.kind, MediaKind.audio);
      expect(media.isOnline, isTrue);
      expect(media.artworkUrl, 'https://img.example/x.jpg');
      expect(media.artist, 'Artist');
    });

    test('search returns tracks, artists and playlists', () async {
      final c = catalog({
        '/v1/tracks/search': [audiusTrack('t')],
        '/v1/users/search': [
          {'id': 'u9', 'name': 'DJ', 'follower_count': 3},
        ],
        '/v1/playlists/search': [
          {'id': 'p1', 'playlist_name': 'Mix', 'is_album': true},
          {'id': 'p2', 'playlist_name': 'Private', 'is_private': true},
        ],
      });
      final r = await c.search('lofi');
      expect(r.tracks.single.id, 't');
      expect(r.artists.single.name, 'DJ');
      expect(r.playlists.map((p) => p.id), ['p1']);
      expect(r.playlists.single.isAlbum, isTrue);
    });

    test('a server error becomes a readable failure', () async {
      final c = catalog({});
      await expectLater(c.trending(), throwsA(isA<OnlineFailure>()));
    });
  });

  group('Jamendo', () {
    JamendoCatalog catalog(Object body) => JamendoCatalog(
      JsonClient(
        MockClient((req) async => http.Response(jsonEncode(body), 200)),
      ),
      clientId: 'id',
    );

    test('download URL only where audiodownload_allowed', () async {
      final c = catalog({
        'headers': {'status': 'success', 'code': 0},
        'results': [
          {
            'id': 1,
            'name': 'Free',
            'audio': 'https://j/1.mp3',
            'audiodownload': 'https://j/1-dl.mp3',
            'audiodownload_allowed': true,
            'artist_name': 'A',
            'album_name': '',
          },
          {
            'id': 2,
            'name': 'Stream only',
            'audio': 'https://j/2.mp3',
            'audiodownload': 'https://j/2-dl.mp3',
            'audiodownload_allowed': false,
          },
        ],
      });
      final tracks = await c.trending();
      expect(tracks.first.downloadUrl, 'https://j/1-dl.mp3');
      expect(tracks.first.album, isNull);
      expect(tracks.first.source, CatalogSource.jamendo);
      expect(tracks.last.canDownload, isFalse);
    });

    test('an invalid client ID says how to fix it', () async {
      final c = catalog({
        'headers': {'status': 'failed', 'code': 5, 'error_message': 'x'},
        'results': [],
      });
      await expectLater(
        c.trending(),
        throwsA(
          isA<OnlineFailure>().having(
            (e) => e.message,
            'message',
            contains('client ID'),
          ),
        ),
      );
    });
  });
}
