import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../playback/domain/media_source.dart';
import '../../application/library_providers.dart';
import '../../data/media_library_repository.dart';
import 'media_tile.dart';

enum _FolderAction { hide, show }

/// A folder row: preview thumbnail, name, item count, size and path, with
/// Hide / Show in its menu.
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
    final noun = kind == MediaKind.video
        ? (folder.count == 1 ? 'video' : 'videos')
        : (folder.count == 1 ? 'song' : 'songs');
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.spaceS),
        child: SizedBox(
          width: 80,
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ThumbnailImage(path: thumb, icon: Icons.folder),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    folder.hidden ? Icons.visibility_off : Icons.folder,
                    size: 14,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${folder.count} $noun'
        '${folder.totalBytes > 0 ? ' · ${formatBytes(folder.totalBytes)}' : ''}'
        '${folder.hidden ? ' · Hidden' : ''}\n${folder.path}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: folder.folder == null
          ? null
          : PopupMenuButton<_FolderAction>(
              tooltip: 'Folder options for ${folder.name}',
              onSelected: (a) => setFolderHidden(
                context,
                ref,
                folder.folder!,
                folder.name,
                hidden: a == _FolderAction.hide,
              ),
              itemBuilder: (context) => [
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
              ],
            ),
    );
  }
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
