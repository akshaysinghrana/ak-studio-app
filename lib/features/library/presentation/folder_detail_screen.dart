import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/domain/media_source.dart';
import '../../../app/providers.dart';
import '../application/library_providers.dart';
import '../data/media_library_repository.dart';
import 'library_actions.dart';
import 'widgets/folder_tile.dart';
import 'widgets/media_collection.dart';

/// Items in one folder (spec 3: folder grouping). Works for hidden folders
/// too, so their contents stay reachable from Hidden folders.
class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({
    super.key,
    required this.kind,
    required this.folder,
  });

  final MediaKind kind;
  final FolderSummary folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(
      libraryProvider((
        kind: kind,
        sort: LibrarySort.title,
        search: '',
        folder: folder.folder ?? MediaLibraryRepository.noFolder,
      )),
    );
    final grid = ref.watch(gridLayoutProvider).value ?? true;
    final hidden = (ref.watch(hiddenFoldersProvider).value ?? const [])
        .contains(folder.folder);
    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          if (kind == MediaKind.video) GridToggleButton(grid: grid),
          if (folder.folder != null)
            IconButton(
              tooltip: hidden ? 'Show folder' : 'Hide folder',
              onPressed: () => setFolderHidden(
                context,
                ref,
                folder.folder!,
                folder.name,
                hidden: !hidden,
              ),
              icon: Icon(
                hidden ? Icons.visibility : Icons.visibility_off_outlined,
              ),
            ),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('This folder is empty.'))
            : RefreshIndicator(
                onRefresh: () => LibraryActions.scan(context, ref),
                child: MediaCollection(
                  entries: list,
                  kind: kind,
                  grid: grid,
                  onPlay: (i) => LibraryActions.playFrom(context, ref, list, i),
                ),
              ),
      ),
    );
  }
}

class GridToggleButton extends ConsumerWidget {
  const GridToggleButton({super.key, required this.grid});

  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: grid ? 'Show as list' : 'Show as grid',
    onPressed: () => ref.read(preferencesProvider).setGridLayout(!grid),
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, a) =>
          RotationTransition(turns: a, child: child),
      child: Icon(
        grid ? Icons.view_list : Icons.grid_view,
        key: ValueKey(grid),
      ),
    ),
  );
}
