import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/library/presentation/home_screen.dart';
import '../features/library/presentation/media_list_screen.dart';
import '../features/player/presentation/player_screen.dart';
import '../features/playback/domain/media_source.dart';
import '../features/playlists/presentation/playlist_detail_screen.dart';
import '../features/playlists/presentation/playlists_screen.dart';
import '../features/poc/engine_poc_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell_scaffold.dart';

abstract final class Routes {
  static const home = '/home';
  static const videos = '/videos';
  static const music = '/music';
  static const settings = '/settings';
  static const playlists = '/playlists';
  static const favorites = '/playlists/favorites';
  static String playlist(String id) => '/playlists/list/$id';
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
      path: Routes.debugEngine,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const EnginePocScreen(),
    ),
  ],
);
