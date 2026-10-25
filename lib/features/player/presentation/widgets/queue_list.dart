import 'package:flutter/material.dart';

import '../../../playback/application/playback_coordinator.dart';
import '../../../playback/domain/media_source.dart';
import '../../../playback/domain/play_queue.dart';

class QueueList extends StatelessWidget {
  const QueueList({super.key, required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: coordinator.playQueue,
      builder: (context, queue, _) {
        if (queue.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Queue (${queue.entries.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (i, e) in queue.entries.indexed)
              ListTile(
                key: ValueKey(e.entryId),
                selected: i == queue.currentIndex,
                leading: Icon(
                  e.media.kind == MediaKind.video
                      ? Icons.movie
                      : Icons.music_note,
                ),
                title: Text(e.media.title),
                // Text marker so the active item is not indicated by colour alone.
                subtitle: i == queue.currentIndex
                    ? const Text('Now playing')
                    : null,
                onTap: () => coordinator.skipToQueueItem(i),
              ),
          ],
        );
      },
    );
  }
}
