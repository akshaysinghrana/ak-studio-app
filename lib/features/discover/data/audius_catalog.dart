import '../../../core/net/json_client.dart';
import '../domain/catalog.dart';

/// Audius public API (no key). Only streamable, ungated tracks are returned;
/// downloads only where the artist enabled them (ADR 0004).
class AudiusCatalog implements MusicCatalog {
  AudiusCatalog(this._client, {this.pageSize = 30});

  final JsonClient _client;
  final int pageSize;

  static const _host = 'api.audius.co';
  static const appName = 'AS_Media';

  @override
  CatalogSource get source => CatalogSource.audius;

  Uri _uri(String path, [Map<String, String> query = const {}]) =>
      Uri.https(_host, '/v1$path', {...query, 'app_name': appName});

  Future<List<Map<String, dynamic>>> _list(Uri uri) async {
    final body = await _client.get(uri);
    final data = body['data'];
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
  }

  static String streamUrl(String id) => Uri.https(
    _host,
    '/v1/tracks/$id/stream',
    {'app_name': appName},
  ).toString();

  static String? _image(Object? sizes, String size) =>
      sizes is Map ? sizes[size] as String? : null;

  /// Null for tracks the app may not play (gated, deleted, not streamable).
  static CatalogTrack? trackFrom(Map<String, dynamic> t) {
    final id = t['id'];
    final title = t['title'];
    if (id is! String || title is! String) return null;
    if (t['is_streamable'] == false ||
        t['is_stream_gated'] == true ||
        t['is_delete'] == true ||
        t['is_available'] == false) {
      return null;
    }
    final user = t['user'];
    final duration = t['duration'];
    final downloadable =
        t['is_downloadable'] == true && t['is_download_gated'] != true;
    final stream = streamUrl(id);
    return CatalogTrack(
      source: CatalogSource.audius,
      id: id,
      title: title,
      streamUrl: stream,
      artist: user is Map ? user['name'] as String? : null,
      artistId: user is Map ? user['id'] as String? : null,
      duration: duration is int ? Duration(seconds: duration) : null,
      artworkUrl: _image(t['artwork'], '480x480'),
      genre: t['genre'] as String?,
      // The artist allowed downloads; the MP3 stream rendition is saved so
      // the file plays in the library.
      downloadUrl: downloadable ? stream : null,
    );
  }

  static CatalogArtist? artistFrom(Map<String, dynamic> u) {
    final id = u['id'];
    final name = u['name'];
    if (id is! String || name is! String) return null;
    return CatalogArtist(
      source: CatalogSource.audius,
      id: id,
      name: name,
      imageUrl: _image(u['profile_picture'], '150x150'),
      followers: u['follower_count'] as int?,
      trackCount: u['track_count'] as int?,
    );
  }

  static CatalogPlaylist? playlistFrom(Map<String, dynamic> p) {
    final id = p['id'];
    final name = p['playlist_name'];
    if (id is! String || name is! String) return null;
    if (p['is_stream_gated'] == true || p['is_private'] == true) return null;
    final user = p['user'];
    return CatalogPlaylist(
      source: CatalogSource.audius,
      id: id,
      name: name,
      owner: user is Map ? user['name'] as String? : null,
      artworkUrl: _image(p['artwork'], '480x480'),
      trackCount: p['track_count'] as int?,
      isAlbum: p['is_album'] == true,
    );
  }

  List<CatalogTrack> _tracks(List<Map<String, dynamic>> rows) =>
      rows.map(trackFrom).nonNulls.toList();

  @override
  Future<List<CatalogTrack>> trending({String? genre}) async => _tracks(
    await _list(
      _uri('/tracks/trending', {
        'time': 'week',
        'limit': '$pageSize',
        'genre': ?genre,
      }),
    ),
  );

  @override
  Future<List<CatalogPlaylist>> featuredPlaylists() async =>
      (await _list(_uri('/playlists/trending', {'limit': '12'})))
          .map(playlistFrom)
          .nonNulls
          .toList();

  @override
  Future<CatalogSearchResults> search(String query) async {
    final q = {'query': query, 'limit': '$pageSize'};
    final results = await Future.wait([
      _list(_uri('/tracks/search', q)),
      _list(_uri('/users/search', {'query': query, 'limit': '10'})),
      _list(_uri('/playlists/search', {'query': query, 'limit': '10'})),
    ]);
    return CatalogSearchResults(
      tracks: _tracks(results[0]),
      artists: results[1].map(artistFrom).nonNulls.toList(),
      playlists: results[2].map(playlistFrom).nonNulls.toList(),
    );
  }

  @override
  Future<List<CatalogTrack>> artistTracks(String artistId) async => _tracks(
    await _list(
      _uri('/users/$artistId/tracks', {'sort': 'plays', 'limit': '50'}),
    ),
  );

  @override
  Future<List<CatalogTrack>> playlistTracks(String playlistId) async =>
      _tracks(await _list(_uri('/playlists/$playlistId/tracks')));
}
