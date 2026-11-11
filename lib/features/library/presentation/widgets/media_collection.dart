import 'package:flutter/material.dart';

import '../../../playback/domain/media_source.dart';
import '../../data/media_library_repository.dart';
import 'media_tile.dart';

/// Items as a grid of cards (videos) or a list; always scrollable so
/// pull-to-refresh works on short lists.
class MediaCollection extends StatelessWidget {
  const MediaCollection({
    super.key,
    required this.entries,
    required this.kind,
    required this.grid,
    required this.onPlay,
    this.selecting = false,
    this.selectedIds = const {},
    this.onToggleSelect,
    this.onEnterSelection,
  });

  final List<LibraryEntry> entries;
  final MediaKind kind;
  final bool grid;
  final void Function(int index) onPlay;
  final bool selecting;
  final Set<String> selectedIds;
  final void Function(LibraryEntry entry)? onToggleSelect;
  final void Function(LibraryEntry entry)? onEnterSelection;

  VoidCallback _onTap(int i) {
    final entry = entries[i];
    if (selecting) {
      return () => onToggleSelect?.call(entry);
    }
    return () => onPlay(i);
  }

  VoidCallback? _onLongPress(int i) {
    if (selecting || onEnterSelection == null) return null;
    final entry = entries[i];
    if (!entry.item.available) return null;
    return () => onEnterSelection!(entry);
  }

  @override
  Widget build(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics();
    if (!grid || kind == MediaKind.audio) {
      return ListView.builder(
        physics: physics,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: entries.length,
        itemBuilder: (context, i) => MediaTile(
          key: ValueKey(entries[i].item.id),
          entry: entries[i],
          onTap: _onTap(i),
          selecting: selecting,
          selected: selectedIds.contains(entries[i].item.id),
          onLongPress: _onLongPress(i),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0, padding = 16.0, maxCell = 260.0;
        final columns =
            ((constraints.maxWidth - padding * 2 + spacing) /
                    (maxCell + spacing))
                .ceil()
                .clamp(2, 6);
        final cell =
            (constraints.maxWidth - padding * 2 - spacing * (columns - 1)) /
            columns;
        // Height follows the real cell width and text scale, so large text
        // never overflows the card.
        final textHeight = MediaQuery.textScalerOf(context).scale(14) * 2 + 24;
        return GridView.builder(
          physics: physics,
          padding: const EdgeInsets.fromLTRB(padding, padding, padding, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cell * 9 / 16 + textHeight.clamp(48, 120),
          ),
          itemCount: entries.length,
          itemBuilder: (context, i) => MediaCard(
            key: ValueKey(entries[i].item.id),
            entry: entries[i],
            onTap: _onTap(i),
            selecting: selecting,
            selected: selectedIds.contains(entries[i].item.id),
            onLongPress: _onLongPress(i),
          ),
        );
      },
    );
  }
}
