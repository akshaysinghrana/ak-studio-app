import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../application/library_providers.dart';
import '../data/media_library_repository.dart';
import 'library_actions.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/media_tile.dart';

/// Home: continue watching/listening and recently added as card carousels
/// (spec 3). History can be cleared here or per item.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(libraryCountProvider).value;
    final scanBusy = ref.watch(scanControllerProvider).busy;
    final continueItems = ref.watch(continueProvider).value ?? const [];
    final recent = ref.watch(recentlyAddedProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Choose files',
            onPressed: () => LibraryActions.importFiles(context, ref),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Scan library',
            onPressed: scanBusy
                ? null
                : () => LibraryActions.scan(context, ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const ScanProgressBar(),
          Expanded(
            child: switch (count) {
              null => const Center(child: CircularProgressIndicator()),
              0 => const LibraryEmptyState(message: 'Your library is empty'),
              _ => RefreshIndicator(
                onRefresh: () => LibraryActions.scan(context, ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppTokens.spaceL),
                  children: [
                    _Carousel(
                      title: 'Continue',
                      entries: continueItems,
                      emptyText: 'Nothing in progress.',
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
    const cardWidth = 220.0;
    final height = cardWidth * 9 / 16 + 28 * textScale * 2 + 16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spaceM,
            AppTokens.spaceM,
            AppTokens.spaceS,
            AppTokens.spaceS,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              ?action,
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: entries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceM,
                  ),
                  child: Text(emptyText),
                )
              : SizedBox(
                  height: height,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceM,
                    ),
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
