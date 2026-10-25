import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../playback/domain/media_source.dart';
import '../application/library_providers.dart';
import '../data/media_library_repository.dart';
import 'library_actions.dart';
import 'widgets/library_empty_state.dart';
import 'widgets/media_tile.dart';

/// Videos or Music tab: search, sort and a lazily built list (spec 4.1, 6.2).
class MediaListScreen extends ConsumerStatefulWidget {
  const MediaListScreen({super.key, required this.kind});

  final MediaKind kind;

  @override
  ConsumerState<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends ConsumerState<MediaListScreen> {
  final _search = TextEditingController();
  LibrarySort _sort = LibrarySort.title;
  String _query = '';

  static const _sortLabels = {
    LibrarySort.title: 'Name',
    LibrarySort.dateAdded: 'Date added',
    LibrarySort.dateModified: 'Date modified',
    LibrarySort.lastPlayed: 'Last played',
    LibrarySort.duration: 'Duration',
    LibrarySort.size: 'Size',
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.kind == MediaKind.video;
    final entries = ref.watch(
      libraryProvider((kind: widget.kind, sort: _sort, search: _query)),
    );
    final scanBusy = ref.watch(scanControllerProvider).busy;

    return Scaffold(
      appBar: AppBar(
        title: Text(isVideo ? 'Videos' : 'Music'),
        actions: [
          PopupMenuButton<LibrarySort>(
            tooltip: 'Sort by',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (context) => [
              for (final s in LibrarySort.values)
                CheckedPopupMenuItem(
                  value: s,
                  checked: s == _sort,
                  child: Text(_sortLabels[s]!),
                ),
            ],
          ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceM,
              0,
              AppTokens.spaceM,
              AppTokens.spaceS,
            ),
            child: SearchBar(
              controller: _search,
              hintText: isVideo ? 'Search videos' : 'Search music',
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
          ),
        ),
      ),
      body: Column(
        children: [
          const ScanProgressBar(),
          Expanded(
            child: entries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Could not load library: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return _query.isNotEmpty
                      ? Center(child: Text('No results for "$_query"'))
                      : LibraryEmptyState(
                          message: isVideo ? 'No videos yet' : 'No music yet',
                        );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => MediaTile(
                    key: ValueKey(list[i].item.id),
                    entry: list[i],
                    onTap: () => LibraryActions.playFrom(context, ref, list, i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
