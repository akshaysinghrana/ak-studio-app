import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/brand_widgets.dart';
import '../../../../shared/data/app_database.dart';
import '../../../player/presentation/widgets/transport_controls.dart';
import '../../../playback/domain/media_source.dart';
import '../../../playlists/application/playlist_providers.dart';
import '../../../playlists/presentation/playlist_dialogs.dart';
import '../../application/library_providers.dart';
import '../../data/media_library_repository.dart';
import '../library_actions.dart';

String formatBytes(int bytes) {
  const mb = 1024 * 1024;
  if (bytes >= 1024 * mb) {
    return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
  }
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / 1024).ceil()} KB';
}

/// Resume fraction for unfinished items, else null.
double? progressFraction(LibraryEntry entry) {
  final p = entry.progress;
  final d = entry.item.durationMs;
  if (p == null || p.completed || d == null || d <= 0) return null;
  return (p.positionMs / d).clamp(0.0, 1.0);
}

enum _Action {
  playNext,
  addToQueue,
  addToPlaylist,
  favorite,
  details,
  showInFolder,
  removeFromHistory,
  rescan,
  remove,
  delete,
}

/// "More options" menu shared by list rows and grid cards.
class MediaActionsButton extends ConsumerWidget {
  const MediaActionsButton({
    super.key,
    required this.entry,
    this.showRemoveFromHistory = false,
    this.color,
  });

  final LibraryEntry entry;

  /// Offered where history is shown (Home → Continue).
  final bool showRemoveFromHistory;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = entry.item;
    final isFavorite = ref.watch(isFavoriteProvider(item.id)).value ?? false;
    return PopupMenuButton<_Action>(
      tooltip: 'More options for ${item.title}',
      iconColor: color,
      onSelected: (a) => _onAction(context, ref, a),
      itemBuilder: (context) => [
        if (item.available) ...[
          const PopupMenuItem(
            value: _Action.playNext,
            child: Text('Play next'),
          ),
          const PopupMenuItem(
            value: _Action.addToQueue,
            child: Text('Add to queue'),
          ),
          const PopupMenuItem(
            value: _Action.addToPlaylist,
            child: Text('Add to playlist…'),
          ),
          PopupMenuItem(
            value: _Action.favorite,
            child: Text(
              isFavorite ? 'Remove from favourites' : 'Add to favourites',
            ),
          ),
        ] else
          const PopupMenuItem(
            value: _Action.rescan,
            child: Text('Rescan library'),
          ),
        const PopupMenuItem(value: _Action.details, child: Text('Details')),
        if (item.folder != null)
          const PopupMenuItem(
            value: _Action.showInFolder,
            child: Text('Show in folder'),
          ),
        if (showRemoveFromHistory)
          const PopupMenuItem(
            value: _Action.removeFromHistory,
            child: Text('Remove from history'),
          ),
        const PopupMenuItem(
          value: _Action.remove,
          child: Text('Remove from library'),
        ),
        if (item.available)
          PopupMenuItem(
            value: _Action.delete,
            child: Text(
              'Delete…',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, _Action a) async {
    final coordinator = ref.read(coordinatorProvider);
    final messenger = ScaffoldMessenger.of(context);
    final title = entry.item.title;
    switch (a) {
      case _Action.playNext:
        await coordinator.playNextInQueue(entry.toMediaSource());
        messenger.showSnackBar(SnackBar(content: Text('"$title" plays next')));
      case _Action.addToQueue:
        await coordinator.addToQueue(entry.toMediaSource());
        messenger.showSnackBar(
          SnackBar(content: Text('Added "$title" to the queue')),
        );
      case _Action.addToPlaylist:
        await showAddToPlaylist(context, ref, [entry.item.id]);
      case _Action.favorite:
        final added = await ref
            .read(playlistRepositoryProvider)
            .toggleFavorite(entry.item.id);
        HapticFeedback.selectionClick();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              added ? 'Added to favourites' : 'Removed from favourites',
            ),
          ),
        );
      case _Action.removeFromHistory:
        await ref
            .read(libraryRepositoryProvider)
            .removeFromHistory(entry.item.id);
        messenger.showSnackBar(
          SnackBar(content: Text('Removed "$title" from history')),
        );
      case _Action.details:
        await showMediaDetailsDialog(context, entry);
      case _Action.showInFolder:
        final folder = entry.item.folder;
        if (folder != null) {
          final ok = await ref.read(mediaStoreProvider).openFolder(folder);
          if (!ok) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not open the folder.')),
            );
          }
        }
      case _Action.rescan:
        await LibraryActions.scan(context, ref);
      case _Action.remove:
        await LibraryActions.confirmRemove(context, ref, entry);
      case _Action.delete:
        await LibraryActions.confirmDelete(context, ref, [
          entry.item,
        ], what: '"$title"');
    }
  }
}

/// One library row: thumbnail, title, real metadata only, resume progress.
/// Unavailable items stay listed with a text label (not colour alone) and
/// offer Rescan / Remove (spec 4.1).
class MediaTile extends ConsumerWidget {
  const MediaTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.showRemoveFromHistory = false,
    this.selecting = false,
    this.selected = false,
    this.onLongPress,
  });

  final LibraryEntry entry;
  final VoidCallback onTap;
  final bool showRemoveFromHistory;
  final bool selecting;
  final bool selected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = entry.item;
    final isFavorite = ref.watch(isFavoriteProvider(item.id)).value ?? false;
    final details = [
      if (item.kind == MediaKind.audio && item.artist != null) item.artist!,
      if (item.durationMs != null)
        formatDuration(Duration(milliseconds: item.durationMs!)),
      if (item.kind == MediaKind.video && item.sizeBytes != null)
        formatBytes(item.sizeBytes!),
    ].join(' · ');
    final fraction = progressFraction(entry);

    return ListTile(
      enabled: item.available,
      selected: selecting && selected,
      onTap: item.available ? onTap : null,
      onLongPress: item.available ? onLongPress : null,
      leading: selecting
          ? ExcludeSemantics(
              child: Checkbox(
                value: selected,
                onChanged: item.available ? (_) => onTap() : null,
              ),
            )
          : MediaThumbnail(entry: entry),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isFavorite)
            const Padding(
              padding: EdgeInsets.only(left: AppTokens.spaceXs),
              child: Icon(Icons.favorite, size: 16, semanticLabel: 'Favourite'),
            ),
        ],
      ),
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
      trailing: selecting
          ? null
          : MediaActionsButton(
              entry: entry,
              showRemoveFromHistory: showRemoveFromHistory,
            ),
    );
  }
}

/// Grid card for videos: large thumbnail with duration badge and progress.
class MediaCard extends ConsumerWidget {
  const MediaCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.showRemoveFromHistory = false,
    this.width,
    this.selecting = false,
    this.selected = false,
    this.onLongPress,
  });

  final LibraryEntry entry;
  final VoidCallback onTap;
  final bool showRemoveFromHistory;

  /// Fixed width for horizontal carousels; null fills the grid cell.
  final double? width;
  final bool selecting;
  final bool selected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = entry.item;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fraction = progressFraction(entry);
    final card = Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusM),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: item.available ? onTap : null,
        onLongPress: item.available ? onLongPress : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaThumbnail(entry: entry, fill: true),
                  if (selecting && selected)
                    ColoredBox(color: scheme.primary.withValues(alpha: 0.28)),
                  if (selecting)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Checkbox(
                            value: selected,
                            onChanged: item.available ? (_) => onTap() : null,
                          ),
                        ),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                  if (item.durationMs != null)
                    Positioned(
                      right: 6,
                      bottom: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          child: Text(
                            formatDuration(
                              Duration(milliseconds: item.durationMs!),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!item.available)
                    ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: Text(
                          'Unavailable',
                          style: text.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  if (fraction != null && item.available)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Semantics(
                        label: 'Watched ${(fraction * 100).round()} percent',
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 3,
                          backgroundColor: Colors.black38,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: item.available ? null : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (!selecting)
                  MediaActionsButton(
                    entry: entry,
                    showRemoveFromHistory: showRemoveFromHistory,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }
}

/// Lazily loaded thumbnail (video frame or MP3 cover art) that fades in.
/// Without one, a generated gradient artwork is shown (never a fabricated
/// album cover).
class MediaThumbnail extends ConsumerWidget {
  const MediaThumbnail({super.key, required this.entry, this.fill = false});

  final LibraryEntry entry;

  /// Fill the parent instead of the fixed list-row size.
  final bool fill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = entry.item;
    final isVideo = item.kind == MediaKind.video;
    final path = item.available
        ? ref.watch(thumbnailProvider(item.locator)).value
        : null;
    final image = ThumbnailImage(path: path, seed: item.title, kind: item.kind);
    if (fill) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusS),
      child: SizedBox(
        width: isVideo ? AppTokens.thumbnailWidth : 56.0,
        height: isVideo ? AppTokens.thumbnailWidth * 9 / 16 : 56.0,
        child: image,
      ),
    );
  }
}

class ThumbnailImage extends StatelessWidget {
  const ThumbnailImage({
    super.key,
    required this.path,
    required this.seed,
    required this.kind,
  });

  final String? path;
  final String seed;
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final placeholder = GeneratedArtwork(seed: seed, kind: kind);
    if (path == null) return placeholder;
    return Image.file(
      File(path!),
      fit: BoxFit.cover,
      cacheWidth: 384,
      errorBuilder: (_, _, _) => placeholder,
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                placeholder,
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: child,
                ),
              ],
            ),
    );
  }
}

/// Item details: where the file is stored, its size, format, resolution and
/// when it was added. The location is selectable so it can be copied out.
Future<void> showMediaDetailsDialog(BuildContext context, LibraryEntry entry) {
  final item = entry.item;
  final rows = <(String, String)>[
    ('Title', item.title),
    ('Type', item.kind == MediaKind.video ? 'Video' : 'Audio'),
    ('Source', _originLabel(item.origin)),
    ('Folder', item.folder ?? 'Imported with Choose files'),
    if (item.displayName != null) ('File', item.displayName!),
    if (item.sizeBytes != null) ('Size', formatBytes(item.sizeBytes!)),
    if (item.durationMs != null)
      ('Duration', formatDuration(Duration(milliseconds: item.durationMs!))),
    if (_fileFormat(item) != null) ('Format', _fileFormat(item)!),
    if (item.width != null && item.height != null)
      ('Resolution', '${item.width}×${item.height}'),
    ('Added', _formatDate(item.addedAt)),
    ('Location', item.locator),
  ];
  return _showRowsDialog(context, title: 'Details', rows: rows);
}

/// Folder details: its path, item count, total size and visibility.
Future<void> showFolderDetailsDialog(
  BuildContext context,
  FolderSummary folder,
  MediaKind kind,
) {
  final noun = kind == MediaKind.video ? 'Videos' : 'Songs';
  final rows = <(String, String)>[
    ('Name', folder.name),
    ('Path', folder.path),
    (noun, '${folder.count}'),
    ('Size', formatBytes(folder.totalBytes)),
    ('Hidden', folder.hidden ? 'Yes' : 'No'),
    if (folder.latestAddedAt != null)
      ('Latest', _formatDate(folder.latestAddedAt!)),
  ];
  return _showRowsDialog(context, title: 'Folder details', rows: rows);
}

Future<void> _showRowsDialog(
  BuildContext context, {
  required String title,
  required List<(String, String)> rows,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Expanded(child: SelectableText(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

String _originLabel(MediaOrigin origin) => switch (origin) {
  MediaOrigin.mediaStore => 'On this device',
  MediaOrigin.downloaded => 'Downloaded in the app',
  MediaOrigin.imported => 'Imported with Choose files',
};

String? _fileFormat(LibraryItem item) {
  final name = item.displayName;
  if (name != null) {
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      return name.substring(dot + 1).toUpperCase();
    }
  }
  final mime = item.mimeType;
  if (mime != null && mime.contains('/')) {
    return mime.split('/').last.toUpperCase();
  }
  return null;
}

String _formatDate(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} '
      '${two(d.hour)}:${two(d.minute)}';
}
