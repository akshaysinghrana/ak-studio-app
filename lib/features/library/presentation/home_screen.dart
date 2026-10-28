import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../playback/domain/media_source.dart';
import '../../playlists/application/playlist_providers.dart';
import '../application/library_providers.dart';
import '../data/media_library_repository.dart';
import 'library_actions.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/media_tile.dart';

/// Home: brand header, library stats, quick access, Continue (with history
/// clearing) and Recently added carousels (spec 3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(libraryCountProvider).value;
    final scanBusy = ref.watch(scanControllerProvider).busy;
    final continueItems = ref.watch(continueProvider).value ?? const [];
    final recent = ref.watch(recentlyAddedProvider).value ?? const [];
    final counts = ref.watch(kindCountsProvider).value ?? const {};
    final playlists = ref.watch(playlistsProvider).value?.length ?? 0;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final header = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
        child: Row(
          children: [
            const AppLogo(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  GradientText(
                    'AS Media',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Choose files',
              onPressed: () => LibraryActions.importFiles(context, ref),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
            IconButton(
              tooltip: 'Scan library',
              onPressed: scanBusy
                  ? null
                  : () => LibraryActions.scan(context, ref),
              icon: const Icon(Icons.radar_rounded),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          header,
          const ScanProgressBar(),
          Expanded(
            child: switch (count) {
              null => const Center(child: CircularProgressIndicator()),
              0 => const LibraryEmptyState(message: 'Your library is empty'),
              _ => RefreshIndicator(
                onRefresh: () => LibraryActions.scan(context, ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          _Stat(
                            label: 'Videos',
                            value: counts[MediaKind.video] ?? 0,
                            icon: Icons.movie_rounded,
                            colors: AppColors.accents[0],
                            onTap: () => context.go(Routes.videos),
                          ),
                          const SizedBox(width: 10),
                          _Stat(
                            label: 'Songs',
                            value: counts[MediaKind.audio] ?? 0,
                            icon: Icons.music_note_rounded,
                            colors: AppColors.accents[1],
                            onTap: () => context.go(Routes.music),
                          ),
                          const SizedBox(width: 10),
                          _Stat(
                            label: 'Playlists',
                            value: playlists,
                            icon: Icons.queue_music_rounded,
                            colors: AppColors.accents[2],
                            onTap: () => context.go(Routes.playlists),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: GlassCard(
                        onTap: () => context.push(Routes.favorites),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            IconBadge(
                              icon: Icons.favorite_rounded,
                              colors: AppColors.accents[4],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Favourites',
                                style: text.titleMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    _Carousel(
                      title: 'Continue watching',
                      entries: continueItems,
                      emptyText: 'Nothing in progress. Start something!',
                      inHistory: true,
                      action: continueItems.isEmpty
                          ? null
                          : TextButton.icon(
                              onPressed: () =>
                                  LibraryActions.confirmClearHistory(
                                    context,
                                    ref,
                                  ),
                              icon: const Icon(
                                Icons.history_toggle_off,
                                size: 18,
                              ),
                              label: const Text('Clear'),
                            ),
                    ),
                    _Carousel(
                      title: 'Recently added',
                      entries: recent,
                      emptyText: 'No recently added media.',
                    ),
                  ],
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, colors: colors, size: 34),
            const SizedBox(height: 10),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 600),
              builder: (context, v, _) => Text('$v', style: text.headlineSmall),
            ),
            Text(
              label,
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Carousel extends ConsumerWidget {
  const _Carousel({
    required this.title,
    required this.entries,
    required this.emptyText,
    this.inHistory = false,
    this.action,
  });

  final String title;
  final List<LibraryEntry> entries;
  final String emptyText;
  final bool inHistory;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    const cardWidth = 230.0;
    final height = cardWidth * 9 / 16 + 28 * textScale * 2 + 16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, action: action),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: entries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    emptyText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : SizedBox(
                  height: height,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => MediaCard(
                      key: ValueKey('$title-${entries[i].item.id}'),
                      entry: entries[i],
                      width: cardWidth,
                      showRemoveFromHistory: inHistory,
                      // Resume a single item rather than queueing the row.
                      onTap: () => LibraryActions.playFrom(context, ref, [
                        entries[i],
                      ], 0),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
