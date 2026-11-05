import '../../../core/net/json_client.dart';
import '../domain/catalog.dart';

/// Jamendo API v3 (Creative Commons music; needs a free client ID from
/// devportal.jamendo.com). Downloads only where `audiodownload_allowed`.
class JamendoCatalog implements MusicCatalog {
  JamendoCatalog(
    this._client, {
    required this.clientId,
    this.downloadFormat = 'mp32',
    this.pageSize = 30,
  });

  final JsonClient _client;
  final String clientId;

  /// `mp32` (VBR high) or `mp31` (96 kbps).
  final String downloadFormat;
  final int pageSize;

  @override
  CatalogSource get source => CatalogSource.jamendo;

  Uri _uri(String path, Map<String, String> query) => Uri.https(
    'api.jamendo.com',
    '/v3.0$path/',
    {'client_id': clientId, 'format': 'json', ...query},
  );

  Future<List<Map<String, dynamic>>> _results(Uri uri) async {
    final body = await _client.get(
      uri,
      describeError: (status, _) => status == 401 || status == 403
          ? 'Jamendo rejected the client ID. Check it in Settings → Online '
                'sources.'
          : 'Jamendo returned an error ($status).',
    );
    final headers = body['headers'];
    if (headers is Map && headers['status'] == 'failed') {
      final code = headers['code'];
      throw OnlineFailure(
        code == 5
            ? 'Jamendo rejected the client ID. Check it in Settings → '
                  'Online sources.'
            : 'Jamendo could not answer (${headers['error_message']}).',
      );
    }
    final results = body['results'];
    return results is List
        ? results.whereType<Map<String, dynamic>>().toList()
        : [];
  }

  Map<String, String> get _trackQuery => {
    'limit': '$pageSize',
    'audioformat': 'mp32',
    'audiodlformat': downloadFormat,
    'imagesize': '300',
  };

  CatalogTrack? trackFrom(Map<String, dynamic> t) {
    final id = t['id'];
    final name = t['name'];
    final audio = t['audio'];
    if (id == null || name is! String || audio is! String || audio.isEmpty) {
      return null;
    }
    final duration = t['duration'];
    final download = t['audiodownload'];
    final allowed = t['audiodownload_allowed'] == true;
    final image = (t['image'] ?? t['album_image']) as String?;
    return CatalogTrack(
      source: CatalogSource.jamendo,
      id: '$id',
      title: name,
      streamUrl: audio,
      artist: t['artist_name'] as String?,
      artistId: t['artist_id']?.toString(),
      album: (t['album_name'] as String?)?.nonEmpty,
      duration: duration is int ? Duration(seconds: duration) : null,
      artworkUrl: image?.nonEmpty,
      downloadUrl: allowed && download is String && download.isNotEmpty
          ? download
          : null,
    );
  }

  List<CatalogTrack> _tracks(List<Map<String, dynamic>> rows) =>
      rows.map(trackFrom).nonNulls.toList();

  @override
  Future<List<CatalogTrack>> trending({String? genre}) async => _tracks(
    await _results(
      _uri('/tracks', {
        ..._trackQuery,
        'order': 'popularity_week',
        'tags': ?genre?.toLowerCase(),
      }),
    ),
  );

  @override
  Future<List<CatalogPlaylist>> featuredPlaylists() async => const [];

  @override
  Future<CatalogSearchResults> search(String query) async {
    final results = await Future.wait([
      _results(
        _uri('/tracks', {
          ..._trackQuery,
          'search': query,
          'order': 'relevance',
        }),
      ),
      _results(_uri('/artists', {'namesearch': query, 'limit': '10'})),
    ]);
    return CatalogSearchResults(
      tracks: _tracks(results[0]),
      artists: [
        for (final a in results[1])
          if (a['id'] != null && a['name'] is String)
            CatalogArtist(
              source: CatalogSource.jamendo,
              id: '${a['id']}',
              name: a['name'] as String,
              imageUrl: (a['image'] as String?)?.nonEmpty,
            ),
      ],
    );
  }

  @override
  Future<List<CatalogTrack>> artistTracks(String artistId) async => _tracks(
    await _results(
      _uri('/tracks', {
        ..._trackQuery,
        'artist_id': artistId,
        'order': 'popularity_total',
      }),
    ),
  );

  @override
  Future<List<CatalogTrack>> playlistTracks(String playlistId) async =>
      const [];
}

extension on String {
  String? get nonEmpty => isEmpty ? null : this;
}
