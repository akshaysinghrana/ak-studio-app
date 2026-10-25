import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../player/presentation/widgets/transport_controls.dart';
import '../application/playlist_providers.dart';
import 'playlist_dialogs.dart';

/// Playlists tab (spec 3, 7.2): Favourites plus user playlists.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final favorites = ref.watch(favoritesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await askPlaylistName(context);
          if (name == null) return;
          final id = await ref.read(playlistRepositoryProvider).create(name);
          if (context.mounted) context.push(Routes.playlist(id));
        },
        icon: const Icon(Icons.add),
        label: const Text('New playlist'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.favorite)),
            title: const Text('Favourites'),
            subtitle: Text('${favorites.length} items'),
            onTap: () => context.push(Routes.favorites),
          ),
          const Divider(),
          ...playlists.when(
            loading: () => [const LinearProgressIndicator()],
            error: (e, _) => [ListTile(title: Text('Could not load: $e'))],
            data: (list) => list.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(AppTokens.spaceL),
                      child: Text(
                        'No playlists yet. Create one, or use "Add to '
                        'playlist" from any song or video.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]
                : [
                    for (final p in list)
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.queue_music),
                        ),
                        title: Text(p.playlist.name),
                        subtitle: Text(
                          '${p.count} items · '
                          '${formatDuration(Duration(milliseconds: p.totalDurationMs))}',
                        ),
                        onTap: () =>
                            context.push(Routes.playlist(p.playlist.id)),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
