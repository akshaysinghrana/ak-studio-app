import 'package:flutter/material.dart';

import '../../../playback/application/playback_coordinator.dart';
import 'queue_list.dart';

/// Now Playing queue as a draggable bottom sheet, reachable from both players.
Future<void> showQueueSheet(
  BuildContext context,
  PlaybackCoordinator coordinator,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        child: QueueList(coordinator: coordinator),
      ),
    ),
  );
}
