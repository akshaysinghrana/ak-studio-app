import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/permissions/media_permissions.dart';
import '../application/library_providers.dart';
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
}
