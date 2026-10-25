import 'package:flutter/material.dart';

import '../../../playback/application/playback_coordinator.dart';

class PlaybackDebugPanel extends StatelessWidget {
  const PlaybackDebugPanel({super.key, required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            coordinator.inBackground,
            coordinator.debugEvents,
            coordinator.playQueue,
          ]),
          builder: (context, _) {
            final style = Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontFamily: 'monospace');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DEBUG', style: Theme.of(context).textTheme.labelLarge),
                Text(
                  'engine: video_player (ExoPlayer)\n'
                  'background: ${coordinator.inBackground.value}\n'
                  'queue index: ${coordinator.playQueue.value.currentIndex}',
                  style: style,
                ),
                const Divider(),
                for (final e in coordinator.debugEvents.value)
                  Text(e, style: style),
              ],
            );
          },
        ),
      ),
    );
  }
}
