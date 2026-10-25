import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../playback/domain/media_source.dart';
import '../../../playback/domain/play_queue.dart';
import '../../../playlists/presentation/playlist_dialogs.dart';

/// Live Now Playing queue (spec 7.1) as a draggable bottom sheet, reachable
/// from both players. Edits apply immediately and never restart the current
/// item.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (context, scroll) => _QueueSheet(scroll: scroll),
    ),
  );
}

enum _QueueAction { clearUpcoming, saveAsPlaylist }

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: coordinator.playQueue,
      builder: (context, queue, _) {
        final (repeatIcon, repeatLabel, nextRepeat) = switch (queue.repeat) {
          QueueRepeat.off => (Icons.repeat, 'Repeat off', QueueRepeat.all),
          QueueRepeat.all => (Icons.repeat_on, 'Repeat all', QueueRepeat.one),
          QueueRepeat.one => (
            Icons.repeat_one_on,
            'Repeat one',
            QueueRepeat.off,
          ),
        };
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Queue · ${queue.entries.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '$repeatLabel. Tap to change.',
                    onPressed: () => coordinator.setRepeat(nextRepeat),
                    icon: Icon(repeatIcon),
                  ),
                  IconButton(
                    tooltip: queue.shuffled ? 'Shuffle on' : 'Shuffle off',
                    isSelected: queue.shuffled,
                    onPressed: queue.isEmpty
                        ? null
                        : () => coordinator.setShuffle(!queue.shuffled),
                    icon: const Icon(Icons.shuffle),
                    selectedIcon: const Icon(Icons.shuffle_on),
                  ),
                  PopupMenuButton<_QueueAction>(
                    tooltip: 'Queue options',
                    enabled: !queue.isEmpty,
                    onSelected: (a) => _onAction(context, ref, a, queue),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _QueueAction.clearUpcoming,
                        enabled: queue.upcomingCount > 0,
                        child: const Text('Clear upcoming'),
                      ),
                      const PopupMenuItem(
                        value: _QueueAction.saveAsPlaylist,
                        child: Text('Save as playlist'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const Center(child: Text('The queue is empty.'))
                  : ReorderableListView.builder(
                      scrollController: scroll,
                      itemCount: queue.entries.length,
                      onReorderItem: coordinator.moveQueueEntry,
                      itemBuilder: (context, i) {
                        final e = queue.entries[i];
                        final isCurrent = i == queue.currentIndex;
                        final tile = ListTile(
                          selected: isCurrent,
                          leading: Icon(
                            isCurrent
                                ? Icons.graphic_eq
                                : e.media.kind == MediaKind.video
                                ? Icons.movie_outlined
                                : Icons.music_note,
                          ),
                          title: Text(
                            e.media.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Text marker so "current" is not colour alone.
                          subtitle: Text(
                            isCurrent
                                ? 'Now playing'
                                : i < queue.currentIndex
                                ? 'Played'
                                : e.media.artist ?? '',
                          ),
                          onTap: isCurrent
                              ? null
                              : () => coordinator.skipToQueueItem(i),
                        );
                        if (isCurrent) {
                          return KeyedSubtree(
                            key: ValueKey(e.entryId),
                            child: tile,
                          );
                        }
                        return Dismissible(
                          key: ValueKey(e.entryId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: const Text('Remove'),
                          ),
                          onDismissed: (_) => coordinator.removeQueueEntry(
                            coordinator.playQueue.value.entries.indexWhere(
                              (x) => x.entryId == e.entryId,
                            ),
                          ),
                          child: tile,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _QueueAction action,
    PlayQueue queue,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _QueueAction.clearUpcoming:
        ref.read(coordinatorProvider).clearUpcoming();
      case _QueueAction.saveAsPlaylist:
        final name = await askPlaylistName(
          context,
          title: 'Save queue as playlist',
          action: 'Save',
        );
        if (name == null) return;
        final (_, result) = await ref
            .read(playlistRepositoryProvider)
            .saveAsPlaylist(name, [for (final e in queue.entries) e.media.id]);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Saved ${result.added} items'
              '${result.duplicates > 0 ? ' (${result.duplicates} duplicates skipped)' : ''}',
            ),
          ),
        );
    }
  }
}
