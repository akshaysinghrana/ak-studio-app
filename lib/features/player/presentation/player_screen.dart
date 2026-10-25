import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../playback/domain/media_source.dart';
import '../../playback/domain/play_queue.dart';
import 'music_player_screen.dart';
import 'video_player_screen.dart';

/// Now Playing route: video items open the video player, audio items the
/// music player (spec 3). Switches when the queue moves between kinds.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: coordinator.playQueue,
      builder: (context, queue, _) =>
          queue.current?.media.kind == MediaKind.video
          ? const VideoPlayerScreen()
          : const MusicPlayerScreen(),
    );
  }
}
