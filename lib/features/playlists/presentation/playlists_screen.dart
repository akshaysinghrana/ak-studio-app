import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../player/presentation/widgets/transport_controls.dart';
import '../../playback/domain/media_source.dart';
import '../application/playlist_providers.dart';
import 'playlist_dialogs.dart';

/// Playlists tab (spec 3, 7.2): Favourites plus user playlists.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final favorites = ref.watch(favoritesProvider).value ?? const [];
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await askPlaylistName(context);
          if (name == null) return;
          final id = await ref.read(playlistRepositoryProvider).create(name);
          if (context.mounted) context.push(Routes.playlist(id));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New playlist'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              borderRadius: BorderRadius.circular(AppTokens.radiusL),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF3D8B),
                      Color(0xFF7B2FFF),
                      AppColors.blue,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: InkWell(
                  onTap: () => context.push(Routes.favorites),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Favourites',
                                style: text.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${favorites.length} items',
                                style: text.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SectionHeader('Your playlists'),
          ...playlists.when(
            loading: () => [const LinearProgressIndicator()],
            error: (e, _) => [ListTile(title: Text('Could not load: $e'))],
            data: (list) => list.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceL),
                      child: Text(
                        'No playlists yet. Create one, or use "Add to playlist" '
                        'from any song or video.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ]
                : [
                    for (final p in list)
                      GlassCard(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.all(10),
                        onTap: () =>
                            context.push(Routes.playlist(p.playlist.id)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusS,
                              ),
                              child: SizedBox.square(
                                dimension: 56,
                                child: GeneratedArtwork(
                                  seed: p.playlist.name,
                                  kind: MediaKind.audio,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.playlist.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleMedium,
                                  ),
                                  Text(
                                    '${p.count} items · '
                                    '${formatDuration(Duration(milliseconds: p.totalDurationMs))}',
                                    style: text.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                  ],
          ),
        ],
      ),
    );
  }
}
