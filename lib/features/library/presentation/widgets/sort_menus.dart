import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/media_library_repository.dart';

const librarySortLabels = {
  LibrarySort.title: 'Name',
  LibrarySort.dateAdded: 'Date added',
  LibrarySort.dateModified: 'Date modified',
  LibrarySort.lastPlayed: 'Last played',
  LibrarySort.duration: 'Duration',
  LibrarySort.size: 'Size',
};

const folderSortLabels = {
  FolderSort.name: 'Name',
  FolderSort.itemCount: 'Most items',
  FolderSort.size: 'Size',
  FolderSort.recent: 'Recently added',
};

/// Sort menu for files; the choice is remembered under [prefKey].
class FileSortButton extends ConsumerWidget {
  const FileSortButton({super.key, required this.prefKey, required this.value});

  final String prefKey;
  final LibrarySort value;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<LibrarySort>(
        tooltip: 'Sort files',
        icon: const Icon(Icons.sort_rounded),
        initialValue: value,
        onSelected: (s) =>
            ref.read(preferencesProvider).setSort(prefKey, s.name),
        itemBuilder: (context) => [
          const PopupMenuItem<LibrarySort>(
            enabled: false,
            child: Text('Sort by'),
          ),
          for (final s in LibrarySort.values)
            CheckedPopupMenuItem(
              value: s,
              checked: s == value,
              child: Text(librarySortLabels[s]!),
            ),
        ],
      );
}

class FolderSortButton extends ConsumerWidget {
  const FolderSortButton({
    super.key,
    required this.prefKey,
    required this.value,
  });

  final String prefKey;
  final FolderSort value;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<FolderSort>(
        tooltip: 'Sort folders',
        icon: const Icon(Icons.sort_rounded),
        initialValue: value,
        onSelected: (s) =>
            ref.read(preferencesProvider).setSort(prefKey, s.name),
        itemBuilder: (context) => [
          const PopupMenuItem<FolderSort>(
            enabled: false,
            child: Text('Sort folders by'),
          ),
          for (final s in FolderSort.values)
            CheckedPopupMenuItem(
              value: s,
              checked: s == value,
              child: Text(folderSortLabels[s]!),
            ),
        ],
      );
}
