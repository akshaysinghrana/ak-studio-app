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
  });

  final List<LibraryEntry> entries;
  final MediaKind kind;
  final bool grid;
  final void Function(int index) onPlay;

  @override
  Widget build(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics();
    if (!grid || kind == MediaKind.audio) {
      return ListView.builder(
        physics: physics,
        itemCount: entries.length,
        itemBuilder: (context, i) => MediaTile(
          key: ValueKey(entries[i].item.id),
          entry: entries[i],
          onTap: () => onPlay(i),
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
          padding: const EdgeInsets.all(padding),
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
            onTap: () => onPlay(i),
          ),
        );
      },
    );
  }
}
