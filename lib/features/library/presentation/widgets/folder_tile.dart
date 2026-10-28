import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/brand_widgets.dart';
import '../../../playback/domain/media_source.dart';
import '../../application/library_providers.dart';
import '../../data/media_library_repository.dart';
import '../library_actions.dart';
import 'media_tile.dart';

enum _FolderAction { hide, show, delete }

/// A folder card: preview thumbnail with a folder badge, name, item count,
/// size and path; Hide / Show / Delete in its menu.
class FolderTile extends ConsumerWidget {
  const FolderTile({
    super.key,
    required this.folder,
    required this.kind,
    required this.onTap,
  });

  final FolderSummary folder;
  final MediaKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sample = folder.sampleLocator;
    final thumb = sample == null
        ? null
        : ref.watch(thumbnailProvider(sample)).value;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final noun = kind == MediaKind.video
        ? (folder.count == 1 ? 'video' : 'videos')
        : (folder.count == 1 ? 'song' : 'songs');
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 62,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radiusS),
                    child: ThumbnailImage(
                      path: thumb,
                      seed: folder.name,
                      kind: kind,
                    ),
                  ),
                ),
                Positioned(
                  left: -6,
                  bottom: -6,
                  child: IconBadge(
                    icon: folder.hidden
                        ? Icons.visibility_off_rounded
                        : Icons.folder_rounded,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${folder.count} $noun'
                  '${folder.totalBytes > 0 ? ' · ${formatBytes(folder.totalBytes)}' : ''}'
                  '${folder.hidden ? ' · Hidden' : ''}',
                  style: text.bodySmall?.copyWith(color: scheme.primary),
                ),
                Text(
                  folder.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_FolderAction>(
            tooltip: 'Folder options for ${folder.name}',
            onSelected: (a) => _onFolderAction(context, ref, a),
            itemBuilder: (context) => [
              if (folder.folder != null)
                if (folder.hidden)
                  const PopupMenuItem(
                    value: _FolderAction.show,
                    child: Text('Show folder'),
                  )
                else
                  const PopupMenuItem(
                    value: _FolderAction.hide,
                    child: Text('Hide folder'),
                  ),
              PopupMenuItem(
                value: _FolderAction.delete,
                child: Text(
                  'Delete folder…',
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onFolderAction(
    BuildContext context,
    WidgetRef ref,
    _FolderAction a,
  ) async {
    switch (a) {
      case _FolderAction.hide || _FolderAction.show:
        await setFolderHidden(
          context,
          ref,
          folder.folder!,
          folder.name,
          hidden: a == _FolderAction.hide,
        );
      case _FolderAction.delete:
        await deleteFolder(context, ref, folder, kind);
    }
  }
}

/// Deletes the videos (or songs) of a folder, trash or permanently.
Future<void> deleteFolder(
  BuildContext context,
  WidgetRef ref,
  FolderSummary folder,
  MediaKind kind,
) async {
  final items =
      (await ref
              .read(libraryRepositoryProvider)
              .itemsInFolder(kind, folder.folder))
          .where((i) => i.available)
          .toList();
  if (!context.mounted || items.isEmpty) return;
  final noun = kind == MediaKind.video ? 'videos' : 'songs';
  await LibraryActions.confirmDelete(
    context,
    ref,
    items,
    what: items.length == 1
        ? 'the only ${noun.substring(0, noun.length - 1)} in "${folder.name}"'
        : 'all ${items.length} $noun in "${folder.name}"',
  );
}

/// Hides or shows a folder, with Undo (hiding is not destructive: nothing
/// is deleted, the items are only left out of lists).
Future<void> setFolderHidden(
  BuildContext context,
  WidgetRef ref,
  String folder,
  String name, {
  required bool hidden,
}) async {
  final repo = ref.read(libraryRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  HapticFeedback.selectionClick();
  if (hidden) {
    await repo.hideFolder(folder);
  } else {
    await repo.showFolder(folder);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(hidden ? 'Hid "$name"' : 'Showing "$name" again'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              hidden ? repo.showFolder(folder) : repo.hideFolder(folder),
        ),
      ),
    );
}
