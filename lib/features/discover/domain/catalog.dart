import '../../playback/domain/media_source.dart';

/// Music catalogues that permit in-app streaming (ADR 0004).
enum CatalogSource {
  audius('Audius'),
  jamendo('Jamendo');

  const CatalogSource(this.label);

  final String label;
}

class CatalogTrack {
  const CatalogTrack({
    required this.source,
    required this.id,
    required this.title,
    required this.streamUrl,
    this.artist,
    this.artistId,
    this.album,
    this.duration,
    this.artworkUrl,
    this.downloadUrl,
    this.genre,
  });

  final CatalogSource source;
  final String id;
  final String title;
  final String streamUrl;
  final String? artist;
  final String? artistId;
  final String? album;
  final Duration? duration;
  final String? artworkUrl;
  final String? genre;

  /// Set only when the source permits downloading this track.
  final String? downloadUrl;

  bool get canDownload => downloadUrl != null;

  /// Stable key across sessions, e.g. `audius:AK3w5q0`.
  String get key => '${source.name}:$id';

  MediaSource toMediaSource() => MediaSource(
    id: key,
    title: title,
    locator: streamUrl,
    kind: MediaKind.audio,
    artist: artist,
    album: album,
    artworkUrl: artworkUrl,
  );
}

class CatalogArtist {
  const CatalogArtist({
    required this.source,
    required this.id,
    required this.name,
    this.imageUrl,
    this.followers,
    this.trackCount,
  });

  final CatalogSource source;
  final String id;
  final String name;
  final String? imageUrl;
  final int? followers;
  final int? trackCount;
}

class CatalogPlaylist {
  const CatalogPlaylist({
    required this.source,
    required this.id,
    required this.name,
    this.owner,
    this.artworkUrl,
    this.trackCount,
    this.isAlbum = false,
  });

  final CatalogSource source;
  final String id;
  final String name;
  final String? owner;
  final String? artworkUrl;
  final int? trackCount;
  final bool isAlbum;
}

class CatalogSearchResults {
  const CatalogSearchResults({
    this.tracks = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  final List<CatalogTrack> tracks;
  final List<CatalogArtist> artists;
  final List<CatalogPlaylist> playlists;

  bool get isEmpty => tracks.isEmpty && artists.isEmpty && playlists.isEmpty;
}

/// A catalogue of streamable music. Implementations only return tracks the
/// app is allowed to play, and set [CatalogTrack.downloadUrl] only where the
/// source allows downloads.
abstract interface class MusicCatalog {
  CatalogSource get source;

  /// Popular tracks this week, optionally for one genre.
  Future<List<CatalogTrack>> trending({String? genre});

  Future<List<CatalogPlaylist>> featuredPlaylists();

  Future<CatalogSearchResults> search(String query);

  Future<List<CatalogTrack>> artistTracks(String artistId);

  Future<List<CatalogTrack>> playlistTracks(String playlistId);
}
