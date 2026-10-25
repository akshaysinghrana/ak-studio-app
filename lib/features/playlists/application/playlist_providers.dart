import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../shared/data/app_database.dart';
import '../../library/data/media_library_repository.dart';
import '../data/playlist_repository.dart';

final playlistsProvider = StreamProvider.autoDispose<List<PlaylistSummary>>(
  (ref) => ref.watch(playlistRepositoryProvider).watchPlaylists(),
);

final playlistProvider = StreamProvider.autoDispose
    .family<PlaylistRow?, String>(
      (ref, id) => ref.watch(playlistRepositoryProvider).watchPlaylist(id),
    );

final playlistItemsProvider = StreamProvider.autoDispose
    .family<List<PlaylistItem>, String>(
      (ref, id) => ref.watch(playlistRepositoryProvider).watchItems(id),
    );

final favoritesProvider = StreamProvider.autoDispose<List<LibraryEntry>>(
  (ref) => ref.watch(playlistRepositoryProvider).watchFavorites(),
);

final isFavoriteProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, mediaId) =>
      ref.watch(playlistRepositoryProvider).watchIsFavorite(mediaId),
);
