import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../library/data/media_library_repository.dart';
import '../../library/presentation/widgets/media_tile.dart';
import '../application/playlist_providers.dart';
import 'playlist_dialogs.dart';

enum _PlaylistAction { rename, delete }

typedef _Row = ({String entryId, LibraryEntry media});

/// A playlist (or Favourites when [playlistId] is null): play (replace the
/// queue) or append, reorder, remove entries; unavailable items stay listed.
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, this.playlistId});

  final String? playlistId;

  bool get _isFavorites => playlistId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = _isFavorites
        ? 'Favourites'
        : ref.watch(playlistProvider(playlistId!)).value?.name ?? '';
    final items = _isFavorites
        ? ref
              .watch(favoritesProvider)
              .whenData(
                (list) => <_Row>[
                  for (final e in list) (entryId: e.item.id, media: e),
                ],
              )
        : ref
              .watch(playlistItemsProvider(playlistId!))
              .whenData(
                (list) => <_Row>[
                  for (final i in list) (entryId: i.entryId, media: i.media),
                ],
              );
    final media = <LibraryEntry>[
      for (final i in items.value ?? const <_Row>[]) i.media,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (!_isFavorites)
            PopupMenuButton<_PlaylistAction>(
              tooltip: 'Playlist options',
              onSelected: (a) => _onAction(context, ref, a, name),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _PlaylistAction.rename,
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  value: _PlaylistAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (list) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: media.any((e) => e.item.available)
                          ? () => _play(context, ref, media, 0)
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: media.any((e) => e.item.available)
                          ? () => _append(context, ref, media)
                          : null,
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Add to queue'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        _isFavorites
                            ? 'Mark songs or videos as favourites to see them here.'
                            : 'This playlist is empty. Use "Add to playlist" '
                                  'from any song or video.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: !_isFavorites,
                      itemCount: list.length,
                      onReorderItem: (from, to) {
                        if (_isFavorites) return;
                        ref
                            .read(playlistRepositoryProvider)
                            .moveEntry(playlistId!, from, to);
                      },
                      itemBuilder: (context, i) {
                        final item = list[i];
                        final tile = MediaTile(
                          entry: item.media,
                          onTap: () => _play(context, ref, media, i),
                        );
                        if (_isFavorites) {
                          return KeyedSubtree(
                            key: ValueKey(item.entryId),
                            child: tile,
                          );
                        }
                        return Dismissible(
                          key: ValueKey(item.entryId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: const Text('Remove'),
                          ),
                          onDismissed: (_) => _removeWithUndo(
                            context,
                            ref,
                            item.entryId,
                            item.media,
                          ),
                          child: tile,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    List<LibraryEntry> media,
    int index,
  ) async {
    final available = [
      for (final e in media)
        if (e.item.available) e,
    ];
    final tapped = media[index];
    if (!tapped.item.available) return;
    await ref.read(coordinatorProvider).playNow([
      for (final e in available) e.toMediaSource(),
    ], startIndex: available.indexOf(tapped));
    if (context.mounted) context.push(Routes.player);
  }

  Future<void> _append(
    BuildContext context,
    WidgetRef ref,
    List<LibraryEntry> media,
  ) async {
    final coordinator = ref.read(coordinatorProvider);
    var n = 0;
    for (final e in media) {
      if (!e.item.available) continue;
      await coordinator.addToQueue(e.toMediaSource());
      n++;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Added $n items to the queue')));
    }
  }

  Future<void> _removeWithUndo(
    BuildContext context,
    WidgetRef ref,
    String entryId,
    LibraryEntry media,
  ) async {
    final repo = ref.read(playlistRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.removeEntry(playlistId!, entryId);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${media.item.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => repo.addMedia(playlistId!, [
            media.item.id,
          ], allowDuplicates: true),
        ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _PlaylistAction action,
    String name,
  ) async {
    final repo = ref.read(playlistRepositoryProvider);
    switch (action) {
      case _PlaylistAction.rename:
        final newName = await askPlaylistName(
          context,
          title: 'Rename playlist',
          initial: name,
          action: 'Rename',
        );
        if (newName != null) await repo.rename(playlistId!, newName);
      case _PlaylistAction.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete playlist?'),
            content: Text(
              '"$name" will be deleted. The songs and videos stay on your '
              'device and in your library.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await repo.delete(playlistId!);
          if (context.mounted) context.pop();
        }
    }
  }
}
