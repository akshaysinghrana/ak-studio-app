import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/account_screen.dart';
import '../features/discover/domain/catalog.dart';
import '../features/discover/presentation/catalog_collection_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/downloads/presentation/downloads_screen.dart';
import '../features/library/presentation/home_screen.dart';
import '../features/library/presentation/media_list_screen.dart';
import '../features/player/presentation/player_screen.dart';
import '../features/playback/domain/media_source.dart';
import '../features/playlists/presentation/playlist_detail_screen.dart';
import '../features/playlists/presentation/playlists_screen.dart';
import '../features/poc/engine_poc_screen.dart';
import '../features/settings/presentation/online_settings_screens.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/youtube/presentation/youtube_player_screen.dart';
import 'shell_scaffold.dart';

abstract final class Routes {
  static const home = '/home';
  static const videos = '/videos';
  static const music = '/music';
  static const settings = '/settings';
  static const account = '/settings/account';
  static const playlists = '/playlists';
  static const favorites = '/playlists/favorites';
  static String playlist(String id) => '/playlists/list/$id';
  static const discover = '/discover';
  static String catalogArtist(CatalogSource source, String id) =>
      '/discover/artist/${source.name}/$id';
  static String catalogPlaylist(CatalogSource source, String id) =>
      '/discover/playlist/${source.name}/$id';
  static const youtubePlayer = '/youtube';
  static const downloads = '/downloads';
  static const downloadSettings = '/downloads/settings';
  static const onlineSources = '/online-sources';
  static const player = '/player';
  static const debugEngine = '/debug/engine';
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({String initialLocation = Routes.home}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.videos,
              builder: (context, state) =>
                  const MediaListScreen(kind: MediaKind.video),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.music,
              builder: (context, state) =>
                  const MediaListScreen(kind: MediaKind.audio),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.discover,
              builder: (context, state) => const DiscoverScreen(),
              routes: [
                GoRoute(
                  path: ':kind/:source/:id',
                  builder: (context, state) {
                    final p = state.pathParameters;
                    return CatalogCollectionScreen(
                      kind: p['kind'] == 'artist'
                          ? CatalogCollectionKind.artist
                          : CatalogCollectionKind.playlist,
                      source:
                          CatalogSource.values.asNameMap()[p['source']] ??
                          CatalogSource.audius,
                      id: p['id']!,
                      title: state.extra as String?,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.playlists,
              builder: (context, state) => const PlaylistsScreen(),
              routes: [
                GoRoute(
                  path: 'favorites',
                  builder: (context, state) => const PlaylistDetailScreen(),
                ),
                GoRoute(
                  path: 'list/:id',
                  builder: (context, state) => PlaylistDetailScreen(
                    playlistId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'account',
                  builder: (context, state) => const AccountScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.player,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const PlayerScreen(),
    ),
    GoRoute(
      path: Routes.youtubePlayer,
      parentNavigatorKey: _rootKey,
      // Arguments are in-memory only; without them there is nothing to play.
      redirect: (context, state) =>
          state.extra is YouTubePlayerArgs ? null : Routes.discover,
      builder: (context, state) =>
          YouTubePlayerScreen(args: state.extra! as YouTubePlayerArgs),
    ),
    GoRoute(
      path: Routes.downloads,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const DownloadsScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          parentNavigatorKey: _rootKey,
          builder: (context, state) => const DownloadSettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: Routes.onlineSources,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const OnlineSourcesScreen(),
    ),
    GoRoute(
      path: Routes.debugEngine,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const EnginePocScreen(),
    ),
  ],
);
