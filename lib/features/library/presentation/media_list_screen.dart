import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../playback/domain/media_source.dart';
import '../../../shared/data/app_database.dart';
import '../application/library_providers.dart';
import '../data/media_library_repository.dart';
import 'file_selection.dart';
import 'folder_detail_screen.dart';
import 'hidden_folders_screen.dart';
import 'library_actions.dart';
import 'widgets/folder_tile.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/media_collection.dart';
import 'widgets/selection_app_bar.dart';
import 'widgets/sort_menus.dart';

/// Videos or Music tab: folders (default) or all items, search, sort,
/// grid/list for videos, pull to refresh (spec 4.1, 6.2).
class MediaListScreen extends ConsumerStatefulWidget {
  const MediaListScreen({super.key, required this.kind});

  final MediaKind kind;

  @override
  ConsumerState<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends ConsumerState<MediaListScreen> {
  final _search = TextEditingController();
  final _selection = FileSelection();
  String _query = '';

  bool get _isVideo => widget.kind == MediaKind.video;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folderView = ref.watch(folderViewProvider(widget.kind)).value ?? true;
    final grid = ref.watch(gridLayoutProvider).value ?? true;
    // Searching always shows matching items, whatever the view.
    final showFolders = folderView && _query.isEmpty;
    final scanBusy = ref.watch(scanControllerProvider).busy;
    final sort =
        ref.watch(librarySortProvider(widget.kind.name)).value ??
        LibrarySort.title;
    final folderSort =
        ref.watch(folderSortProvider(widget.kind)).value ?? FolderSort.name;

    final visibleItems = showFolders
        ? const <LibraryItem>[]
        : [
            for (final e
                in ref
                        .watch(
                          libraryProvider((
                            kind: widget.kind,
                            sort: sort,
                            search: _query,
                            folder: null,
                          )),
                        )
                        .value ??
                    const <LibraryEntry>[])
              if (e.item.available) e.item,
          ];

    final searchBar = PreferredSize(
      preferredSize: const Size.fromHeight(124),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.spaceM,
          0,
          AppTokens.spaceM,
          AppTokens.spaceS,
        ),
        child: Column(
          children: [
            SearchBar(
              controller: _search,
              hintText: _isVideo ? 'Search videos' : 'Search music',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppTokens.spaceS),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  const ButtonSegment(
                    value: true,
                    icon: Icon(Icons.folder_outlined),
                    label: Text('Folders'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(
                      _isVideo
                          ? Icons.video_library_outlined
                          : Icons.library_music_outlined,
                    ),
                    label: Text(_isVideo ? 'All videos' : 'All songs'),
                  ),
                ],
                selected: {folderView},
                onSelectionChanged: (s) {
                  if (_selection.active) {
                    setState(_selection.clear);
                  }
                  ref
                      .read(preferencesProvider)
                      .setFolderView(widget.kind.name, s.single);
                },
              ),
            ),
          ],
        ),
      ),
    );

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
                bottom: searchBar,
              )
            : AppBar(
                title: Text(_isVideo ? 'Videos' : 'Music'),
                actions: [
                  if (showFolders)
                    FolderSortButton(
                      prefKey: '${widget.kind.name}.folders',
                      value: folderSort,
                    )
                  else ...[
                    FileSortButton(prefKey: widget.kind.name, value: sort),
                    IconButton(
                      tooltip: 'Select files',
                      onPressed: visibleItems.isEmpty
                          ? null
                          : () => setState(() {
                              _selection.active = true;
                            }),
                      icon: const Icon(Icons.checklist_rounded),
                    ),
                  ],
                  if (_isVideo && !showFolders) GridToggleButton(grid: grid),
                  IconButton(
                    tooltip: 'Choose files',
                    onPressed: () => LibraryActions.importFiles(context, ref),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Scan library',
                    onPressed: scanBusy
                        ? null
                        : () => LibraryActions.scan(context, ref),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
                bottom: searchBar,
              ),
        body: Column(
          children: [
            const ScanProgressBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => LibraryActions.scan(context, ref),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: showFolders
                      ? KeyedSubtree(
                          key: const ValueKey('folders'),
                          child: _folders(folderSort),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('items'),
                          child: _items(grid, sort),
                        ),
                ),
              ),
            ),
          ],
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

  Widget _folders(FolderSort folderSort) {
    final folders = ref.watch(foldersProvider(widget.kind));
    return folders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load folders: $e')),
      data: (all) {
        if (all.isEmpty) return _empty();
        final visible = sortFolders([
          for (final f in all)
            if (!f.hidden) f,
        ], folderSort);
        final hiddenCount = all.length - visible.length;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          children: [
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppTokens.spaceL),
                child: Text(
                  'All folders are hidden.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final f in visible)
              FolderTile(
                key: ValueKey(f.folder),
                folder: f,
                kind: widget.kind,
                onTap: () => _openFolder(f),
              ),
            if (hiddenCount > 0)
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text('Hidden folders ($hiddenCount)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HiddenFoldersScreen(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _items(bool grid, LibrarySort sort) {
    final entries = ref.watch(
      libraryProvider((
        kind: widget.kind,
        sort: sort,
        search: _query,
        folder: null,
      )),
    );
    return entries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load library: $e')),
      data: (list) {
        if (list.isEmpty) {
          return _query.isNotEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceL),
                      child: Text(
                        'No results for "$_query"',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : _empty();
        }
        return MediaCollection(
          entries: list,
          kind: widget.kind,
          grid: grid,
          onPlay: (i) => LibraryActions.playFrom(context, ref, list, i),
          selecting: _selection.active,
          selectedIds: _selection.items.keys.toSet(),
          onToggleSelect: (e) => setState(() => _selection.toggle(e.item)),
          onEnterSelection: (e) {
            HapticFeedback.selectionClick();
            setState(() => _selection.begin(e.item));
          },
        );
      },
    );
  }

  Widget _empty() =>
      LibraryEmptyState(message: _isVideo ? 'No videos yet' : 'No music yet');

  void _openFolder(FolderSummary folder) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FolderDetailScreen(kind: widget.kind, folder: folder),
    ),
  );
}
