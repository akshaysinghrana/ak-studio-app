import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../application/playlist_providers.dart';

/// Asks for a playlist name; returns null when cancelled.
Future<String?> askPlaylistName(
  BuildContext context, {
  String title = 'New playlist',
  String initial = '',
  String action = 'Create',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(action),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// Lets the user pick (or create) a playlist and adds [mediaIds] to it,
/// asking before adding items that are already there (spec 7.2).
Future<void> showAddToPlaylist(
  BuildContext context,
  WidgetRef ref,
  List<String> mediaIds,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(playlistRepositoryProvider);
  final playlistId = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final playlists = ref.watch(playlistsProvider).value ?? const [];
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Add to playlist')),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New playlist'),
                onTap: () async {
                  final name = await askPlaylistName(context);
                  if (name == null) return;
                  final id = await repo.create(name);
                  if (context.mounted) Navigator.pop(context, id);
                },
              ),
              for (final p in playlists)
                ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(p.playlist.name),
                  subtitle: Text('${p.count} items'),
                  onTap: () => Navigator.pop(context, p.playlist.id),
                ),
            ],
          ),
        );
      },
    ),
  );
  if (playlistId == null) return;
  final result = await repo.addMedia(playlistId, mediaIds);
  if (result.duplicates > 0 && context.mounted) {
    final again = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Already in playlist'),
        content: Text(
          result.duplicates == 1
              ? 'This item is already in the playlist. Add it again?'
              : '${result.duplicates} items are already in the playlist. '
                    'Add them again?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add again'),
          ),
        ],
      ),
    );
    if (again == true) {
      final existing = await repo.watchItems(playlistId).first;
      final present = {for (final i in existing) i.media.item.id};
      await repo.addMedia(playlistId, [
        for (final id in mediaIds)
          if (present.contains(id)) id,
      ], allowDuplicates: true);
    }
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.added > 0 ? 'Added to playlist' : 'Playlist unchanged',
      ),
    ),
  );
}
