import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../discover/application/online_providers.dart';
import '../../discover/domain/catalog.dart';
import '../application/download_manager.dart';

/// UI flows around [DownloadManager]: duplicate prompts and feedback.
abstract final class DownloadActions {
  static Future<void> track(
    BuildContext context,
    WidgetRef ref,
    CatalogTrack track,
  ) => _run(
    context,
    (force) =>
        ref.read(downloadManagerProvider).downloadTrack(track, force: force),
    track.title,
  );

  static Future<void> url(
    BuildContext context,
    WidgetRef ref,
    String url, {
    String? title,
  }) => _run(
    context,
    (force) => ref
        .read(downloadManagerProvider)
        .downloadUrl(url, title: title, force: force),
    title ?? 'Link',
  );

  static Future<void> _run(
    BuildContext context,
    Future<DownloadRequest> Function(bool force) start,
    String title,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    var result = await start(false);
    if (result is DownloadDuplicate && context.mounted) {
      final again = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (context) => AlertDialog(
          title: const Text('Download again?'),
          content: Text(switch (result) {
            DownloadDuplicate(:final existing)
                when existing.savedPath != null =>
              '"${existing.title}" is already downloaded.',
            DownloadDuplicate(:final existing) =>
              '"${existing.title}" is already in your downloads.',
            _ => '',
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Download again'),
            ),
          ],
        ),
      );
      if (again != true) return;
      result = await start(true);
    }
    switch (result) {
      case DownloadStarted():
        messenger.showSnackBar(
          SnackBar(
            content: Text('Downloading "${result.row.title}"'),
            // Progress is on the track and in Downloads; don't cover the
            // screen until dismissed.
            persist: false,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => router.push(Routes.downloads),
            ),
          ),
        );
      case DownloadRejected(:final reason):
        messenger.showSnackBar(SnackBar(content: Text(reason)));
      case DownloadDuplicate():
        break;
    }
  }
}
