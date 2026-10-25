import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../player/presentation/widgets/transport_controls.dart';
import '../../../playback/domain/media_source.dart';
import '../../application/library_providers.dart';
import '../../data/media_library_repository.dart';
import '../library_actions.dart';

enum _TileAction { playNext, addToQueue, rescan, remove }

/// One library row: thumbnail, title, real metadata only, resume progress,
/// and a menu with queue actions. Unavailable items stay listed with a text
/// label (not colour alone) and offer Rescan / Remove (spec 4.1).
class MediaTile extends ConsumerWidget {
  const MediaTile({super.key, required this.entry, required this.onTap});

  final LibraryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = entry.item;
    final progress = entry.progress;
    final details = [
      if (item.kind == MediaKind.audio && item.artist != null) item.artist!,
      if (item.durationMs != null)
        formatDuration(Duration(milliseconds: item.durationMs!)),
      if (item.kind == MediaKind.video && item.sizeBytes != null)
        _formatBytes(item.sizeBytes!),
    ].join(' · ');
    final fraction =
        progress != null &&
            !progress.completed &&
            item.durationMs != null &&
            item.durationMs! > 0
        ? (progress.positionMs / item.durationMs!).clamp(0.0, 1.0)
        : null;

    return ListTile(
      enabled: item.available,
      onTap: item.available ? onTap : null,
      leading: MediaThumbnail(entry: entry),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.available
                ? details
                : 'Unavailable: file missing or access removed',
          ),
          if (fraction != null && item.available)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spaceXs),
              child: Semantics(
                label: 'Watched ${(fraction * 100).round()} percent',
                child: LinearProgressIndicator(value: fraction, minHeight: 3),
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<_TileAction>(
        tooltip: 'More options for ${item.title}',
        onSelected: (action) => _onAction(context, ref, action),
        itemBuilder: (context) => [
          if (item.available) ...[
            const PopupMenuItem(
              value: _TileAction.playNext,
              child: Text('Play next'),
            ),
            const PopupMenuItem(
              value: _TileAction.addToQueue,
              child: Text('Add to queue'),
            ),
          ] else
            const PopupMenuItem(
              value: _TileAction.rescan,
              child: Text('Rescan library'),
            ),
          const PopupMenuItem(
            value: _TileAction.remove,
            child: Text('Remove from library'),
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _TileAction action,
  ) async {
    final coordinator = ref.read(coordinatorProvider);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _TileAction.playNext:
        await coordinator.playNextInQueue(entry.toMediaSource());
        messenger.showSnackBar(
          SnackBar(content: Text('"${entry.item.title}" plays next')),
        );
      case _TileAction.addToQueue:
        await coordinator.addToQueue(entry.toMediaSource());
        messenger.showSnackBar(
          SnackBar(content: Text('Added "${entry.item.title}" to the queue')),
        );
      case _TileAction.rescan:
        await LibraryActions.scan(context, ref);
      case _TileAction.remove:
        await LibraryActions.confirmRemove(context, ref, entry);
    }
  }

  static String _formatBytes(int bytes) {
    const mb = 1024 * 1024;
    if (bytes >= 1024 * mb) {
      return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
    }
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).ceil()} KB';
  }
}

/// Lazily loaded thumbnail; a neutral icon when none exists (never invented
/// artwork).
class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail({super.key, required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideo = entry.item.kind == MediaKind.video;
    final width = isVideo ? AppTokens.thumbnailWidth : 56.0;
    final height = isVideo ? AppTokens.thumbnailWidth * 9 / 16 : 56.0;
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Icon(
      isVideo ? Icons.movie_outlined : Icons.music_note,
      color: scheme.onSurfaceVariant,
    );
    final path = entry.item.available
        ? ref.watch(thumbnailProvider(entry.item.locator)).value
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.spaceS),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: path == null
              ? placeholder
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 256,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}
