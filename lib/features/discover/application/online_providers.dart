import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../app/providers.dart';
import '../../../core/net/json_client.dart';
import '../../../core/platform/screen_control.dart';
import '../../../shared/data/app_database.dart';
import '../../downloads/application/download_manager.dart';
import '../../youtube/data/youtube_api.dart';
import '../data/audius_catalog.dart';
import '../data/jamendo_catalog.dart';
import '../domain/catalog.dart';

// Online discovery and downloads (ADR 0004).

const _youtubeKeyDefine = String.fromEnvironment('YOUTUBE_API_KEY');
const _jamendoIdDefine = String.fromEnvironment('JAMENDO_CLIENT_ID');

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final jsonClientProvider = Provider<JsonClient>(
  (ref) => JsonClient(ref.watch(httpClientProvider)),
);

/// The saved key, else the build-time define; null when not set up.
final youtubeApiKeyProvider = StreamProvider<String?>(
  (ref) => ref
      .watch(preferencesProvider)
      .watchYoutubeApiKey()
      .map((v) => _orDefine(v, _youtubeKeyDefine)),
);

final jamendoClientIdProvider = StreamProvider<String?>(
  (ref) => ref
      .watch(preferencesProvider)
      .watchJamendoClientId()
      .map((v) => _orDefine(v, _jamendoIdDefine)),
);

String? _orDefine(String? saved, String define) {
  final value = (saved?.trim().isNotEmpty ?? false) ? saved!.trim() : define;
  return value.isEmpty ? null : value;
}

final _appIdentityProvider = FutureProvider<({String? package, String? sha1})>(
  (ref) => const ScreenControl().appIdentity(),
);

/// Null until a YouTube Data API key is configured.
final youtubeApiProvider = FutureProvider<YouTubeApi?>((ref) async {
  final key = ref.watch(youtubeApiKeyProvider).value;
  if (key == null) return null;
  final identity = await ref.watch(_appIdentityProvider.future);
  return YouTubeApi(
    ref.watch(jsonClientProvider),
    apiKey: key,
    androidPackage: identity.package,
    androidCertSha1: identity.sha1,
  );
});

/// Device region for YouTube charts and search ranking.
String? get deviceRegion =>
    PlatformDispatcher.instance.locale.countryCode?.toUpperCase();

final audiusCatalogProvider = Provider<MusicCatalog>(
  (ref) => AudiusCatalog(ref.watch(jsonClientProvider)),
);

/// Null until a Jamendo client ID is configured.
final jamendoCatalogProvider = Provider<MusicCatalog?>((ref) {
  final id = ref.watch(jamendoClientIdProvider).value;
  if (id == null) return null;
  final quality = ref.watch(jamendoQualityProvider).value ?? 'mp32';
  return JamendoCatalog(
    ref.watch(jsonClientProvider),
    clientId: id,
    downloadFormat: quality,
  );
});

final jamendoQualityProvider = StreamProvider<String>(
  (ref) => ref.watch(preferencesProvider).watchJamendoQuality(),
);

final catalogProvider = Provider.family<MusicCatalog?, CatalogSource>(
  (ref, source) => switch (source) {
    CatalogSource.audius => ref.watch(audiusCatalogProvider),
    CatalogSource.jamendo => ref.watch(jamendoCatalogProvider),
  },
);

/// The catalogue shown in Discover → Music.
class SelectedCatalog extends Notifier<CatalogSource> {
  @override
  CatalogSource build() => CatalogSource.audius;

  void select(CatalogSource source) => state = source;
}

final selectedCatalogProvider =
    NotifierProvider<SelectedCatalog, CatalogSource>(SelectedCatalog.new);

MusicCatalog _require(Ref ref, CatalogSource source) {
  final catalog = ref.watch(catalogProvider(source));
  if (catalog == null) {
    throw const OnlineFailure(
      'Jamendo is not set up. Add a client ID in Settings → Online sources.',
    );
  }
  return catalog;
}

final trendingTracksProvider = FutureProvider.autoDispose
    .family<List<CatalogTrack>, (CatalogSource, String?)>(
      (ref, args) => _require(ref, args.$1).trending(genre: args.$2),
    );

final featuredPlaylistsProvider = FutureProvider.autoDispose
    .family<List<CatalogPlaylist>, CatalogSource>(
      (ref, source) => _require(ref, source).featuredPlaylists(),
    );

final catalogSearchProvider = FutureProvider.autoDispose
    .family<CatalogSearchResults, (CatalogSource, String)>(
      (ref, args) => _require(ref, args.$1).search(args.$2),
    );

final artistTracksProvider = FutureProvider.autoDispose
    .family<List<CatalogTrack>, (CatalogSource, String)>(
      (ref, args) => _require(ref, args.$1).artistTracks(args.$2),
    );

final catalogPlaylistTracksProvider = FutureProvider.autoDispose
    .family<List<CatalogTrack>, (CatalogSource, String)>(
      (ref, args) => _require(ref, args.$1).playlistTracks(args.$2),
    );

final youtubePopularProvider = FutureProvider.autoDispose<List<YouTubeVideo>>((
  ref,
) async {
  final api = await ref.watch(youtubeApiProvider.future);
  if (api == null) return const [];
  return api.popularMusic(regionCode: deviceRegion);
});

final youtubeSearchProvider = FutureProvider.autoDispose
    .family<List<YouTubeVideo>, String>((ref, query) async {
      final api = await ref.watch(youtubeApiProvider.future);
      if (api == null) return const [];
      return api.search(query, regionCode: deviceRegion);
    });

// Downloads.

final downloadManagerProvider = Provider<DownloadManager>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final downloadsProvider = StreamProvider<List<DownloadRow>>(
  (ref) => ref.watch(downloadManagerProvider).watchAll(),
);

final downloadsBySourceProvider = StreamProvider<Map<String, DownloadRow>>(
  (ref) => ref.watch(downloadManagerProvider).watchBySource(),
);

final activeDownloadCountProvider = StreamProvider<int>(
  (ref) => ref.watch(downloadManagerProvider).watchActiveCount(),
);
