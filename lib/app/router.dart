import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/library/presentation/home_screen.dart';
import '../features/library/presentation/media_list_screen.dart';
import '../features/player/presentation/player_screen.dart';
import '../features/playback/domain/media_source.dart';
import '../features/poc/engine_poc_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell_scaffold.dart';

abstract final class Routes {
  static const home = '/home';
  static const videos = '/videos';
  static const music = '/music';
  static const settings = '/settings';
  static const player = '/player';
  static const debugEngine = '/debug/engine';
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({String initialLocation = Routes.home}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: initialLocation,
  routes: [
    // Playlists join the bottom navigation in Phase 4, once they work; no
    // placeholder tab is shown before then (spec 2: never show dead controls).
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
