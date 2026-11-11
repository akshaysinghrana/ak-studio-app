import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/domain/media_source.dart';
import '../../../app/providers.dart';
import '../application/library_providers.dart';
import '../data/media_library_repository.dart';
import 'file_selection.dart';
import 'library_actions.dart';
import 'widgets/folder_tile.dart';
import 'widgets/media_collection.dart';
import 'widgets/selection_app_bar.dart';
import 'widgets/sort_menus.dart';

/// Items in one folder (spec 3: folder grouping). Works for hidden folders
/// too, so their contents stay reachable from Hidden folders.
class FolderDetailScreen extends ConsumerStatefulWidget {
  const FolderDetailScreen({
    super.key,
    required this.kind,
    required this.folder,
  });

  final MediaKind kind;
  final FolderSummary folder;

  @override
  ConsumerState<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<FolderDetailScreen> {
  final _selection = FileSelection();

  MediaKind get kind => widget.kind;
  FolderSummary get folder => widget.folder;

  @override
  Widget build(BuildContext context) {
    final sort =
        ref.watch(librarySortProvider(kind.name)).value ?? LibrarySort.title;
    final entries = ref.watch(
      libraryProvider((
        kind: kind,
        sort: sort,
        search: '',
        folder: folder.folder ?? MediaLibraryRepository.noFolder,
      )),
    );
    final grid = ref.watch(gridLayoutProvider).value ?? true;
    final hidden = (ref.watch(hiddenFoldersProvider).value ?? const [])
        .contains(folder.folder);
    final visibleItems = [
      for (final e in entries.value ?? const <LibraryEntry>[])
        if (e.item.available) e.item,
    ];

    return PopScope(
      canPop: !_selection.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selection.clear);
      },
      child: Scaffold(
        appBar: _selection.active
            ? SelectionAppBar(
                selectedCount: _selection.count,
                allVisibleSelected: _selection.allSelected(visibleItems),
                onClose: () => setState(_selection.clear),
                onSelectAll: () => setState(() {
                  _selection.selectAll(visibleItems);
                }),
                onDelete: () => _deleteSelected(),
              )
            : AppBar(
                title: Text(folder.name),
                actions: [
                  FileSortButton(prefKey: kind.name, value: sort),
                  if (kind == MediaKind.video) GridToggleButton(grid: grid),
                  IconButton(
                    tooltip: 'Select files',
                    onPressed: visibleItems.isEmpty
                        ? null
                        : () => setState(() {
                            _selection.active = true;
                          }),
                    icon: const Icon(Icons.checklist_rounded),
                  ),
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
                        hidden
                            ? Icons.visibility
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Delete folder',
                    onPressed: () => deleteFolder(context, ref, folder, kind),
                    icon: const Icon(Icons.delete_outline_rounded),
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
                    onPlay: (i) =>
                        LibraryActions.playFrom(context, ref, list, i),
                    selecting: _selection.active,
                    selectedIds: _selection.items.keys.toSet(),
                    onToggleSelect: (e) =>
                        setState(() => _selection.toggle(e.item)),
                    onEnterSelection: (e) {
                      HapticFeedback.selectionClick();
                      setState(() => _selection.begin(e.item));
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final items = _selection.items.values.toList();
    final ok = await LibraryActions.confirmDelete(
      context,
      ref,
      items,
      what: items.length == 1
          ? '"${items.single.title}"'
          : '${items.length} files',
    );
    if (ok && mounted) setState(_selection.clear);
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
