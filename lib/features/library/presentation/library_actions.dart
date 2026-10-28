import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/permissions/media_permissions.dart';
import '../application/library_providers.dart';
import '../../../shared/data/app_database.dart';
import '../data/media_library_repository.dart';

/// Shared user actions for library screens, with snackbar feedback.
abstract final class LibraryActions {
  static Future<void> scan(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(scanControllerProvider.notifier).scan();
    final state = ref.read(scanControllerProvider);
    final message = switch (state.status) {
      ScanStatus.done => _summaryText(state),
      ScanStatus.noAccess =>
        state.permanentlyDenied
            ? 'Media access is off. Enable it in system settings, or use '
                  'Choose files.'
            : 'Media access was not allowed. You can still use Choose files.',
      ScanStatus.failed => 'Scan failed: ${state.error}',
      _ => null,
    };
    if (message == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: state.permanentlyDenied
            ? SnackBarAction(
                label: 'Settings',
                onPressed: () =>
                    ref.read(mediaPermissionsProvider).openSettings(),
              )
            : null,
      ),
    );
  }

  static String _summaryText(ScanState state) {
    final s = state.summary!;
    final parts = [
      '${s.added} added',
      if (s.missing > 0) '${s.missing} no longer found',
      if (s.restored > 0) '${s.restored} found again',
    ];
    final limited = state.access.values.contains(MediaAccess.limited)
        ? ' Only videos you selected are visible.'
        : '';
    return 'Library updated: ${parts.join(', ')}.$limited';
  }

  static Future<void> importFiles(
    BuildContext context,
    WidgetRef ref, {
    bool playNow = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ImportSummary result;
    try {
      result = await ref.read(libraryRepositoryProvider).importDocuments();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
      return;
    }
    if (result.imported.isEmpty && result.skipped == 0) return;
    final skipped = result.skipped > 0
        ? ' ${result.skipped} unsupported file(s) skipped.'
        : '';
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added ${result.imported.length} file(s).$skipped'),
      ),
    );
    if (playNow && result.imported.isNotEmpty) {
      await ref.read(coordinatorProvider).playNow([
        for (final e in result.imported) e.toMediaSource(),
      ]);
      router.push(Routes.player);
    }
  }

  /// Plays [entries] from [index] onward (available items only) and opens
  /// the player.
  static Future<void> playFrom(
    BuildContext context,
    WidgetRef ref,
    List<LibraryEntry> entries,
    int index,
  ) async {
    final router = GoRouter.of(context);
    final queue = [
      for (final e in entries.skip(index))
        if (e.item.available) e.toMediaSource(),
    ];
    if (queue.isEmpty) return;
    await ref.read(coordinatorProvider).playNow(queue);
    router.push(Routes.player);
  }

  static Future<void> confirmRemove(
    BuildContext context,
    WidgetRef ref,
    LibraryEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from library?'),
        content: Text(
          '"${entry.item.title}" will be removed from the app\'s library, its '
          'playlists and favourites, and its saved position cleared. The file '
          'on your device is not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(libraryRepositoryProvider).remove(entry.item.id);
    }
  }

  /// Clears all watch/listen history after confirmation.
  static Future<void> confirmClearHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear watch history?'),
        content: const Text(
          'Removes "Continue" items, resume positions and last-played '
          'information. Your library, playlists and favourites are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(libraryRepositoryProvider).clearHistory();
    messenger.showSnackBar(
      const SnackBar(content: Text('Watch history cleared')),
    );
  }

  /// Asks how to delete [items] (trash or permanently), lets Android confirm,
  /// then updates the library and the queue. [what] describes the selection,
  /// e.g. `"Holiday"` or `the 12 videos in "Camera"`.
  static Future<void> confirmDelete(
    BuildContext context,
    WidgetRef ref,
    List<LibraryItem> items, {
    required String what,
  }) async {
    if (items.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(libraryRepositoryProvider);
    final trashSupported =
        await ref.read(mediaStoreProvider).isTrashSupported() &&
        items.every((i) => i.origin == MediaOrigin.mediaStore);
    if (!context.mounted) return;
    final trash = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Delete $what?'),
                subtitle: const Text(
                  'This deletes the files from your phone, not just from the app.',
                ),
              ),
              if (trashSupported)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Move to trash'),
                  subtitle: const Text(
                    'Can be restored from the Files app for about 30 days',
                  ),
                  onTap: () => Navigator.pop(context, true),
                ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: scheme.error),
                title: Text(
                  'Delete permanently',
                  style: TextStyle(color: scheme.error),
                ),
                subtitle: const Text('Cannot be undone'),
                onTap: () => Navigator.pop(context, false),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (trash == null) return;
    try {
      final ok = await repo.deleteFiles(items, trash: trash);
      if (!ok) return; // declined in the system dialog
      await ref.read(coordinatorProvider).removeMedia({
        for (final i in items) i.id,
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            trash
                ? 'Moved ${items.length == 1 ? 'to' : '${items.length} files to'} trash'
                : 'Deleted ${items.length == 1 ? '' : '${items.length} files '}permanently',
          ),
        ),
      );
    } on PlatformException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete: ${e.message ?? e.code}')),
      );
    }
  }
}
