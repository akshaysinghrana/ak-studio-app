import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../application/library_providers.dart';
import '../data/media_library_repository.dart';
import 'library_actions.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/media_tile.dart';

/// Home: continue watching/listening and recently added (spec 3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(libraryCountProvider).value;
    final scanBusy = ref.watch(scanControllerProvider).busy;
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
              _ => ListView(
                children: [
                  _Section(
                    title: 'Continue',
                    entries: ref.watch(continueProvider).value ?? const [],
                    emptyText: 'Nothing in progress.',
                  ),
                  _Section(
                    title: 'Recently added',
                    entries: ref.watch(recentlyAddedProvider).value ?? const [],
                    emptyText: 'No recently added media.',
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.title,
    required this.entries,
    required this.emptyText,
  });

  final String title;
  final List<LibraryEntry> entries;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spaceM,
            AppTokens.spaceM,
            AppTokens.spaceM,
            AppTokens.spaceXs,
          ),
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceM),
            child: Text(emptyText),
          ),
        for (final (i, e) in entries.indexed)
          MediaTile(
            key: ValueKey('$title-${e.item.id}'),
            entry: e,
            // Resume a single item from Home rather than queueing the section.
            onTap: () => LibraryActions.playFrom(context, ref, [entries[i]], 0),
          ),
      ],
    );
  }
}
