import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../playback/domain/media_source.dart';
import '../../playback/domain/play_queue.dart';
import 'widgets/background_audio_switch.dart';
import 'widgets/playback_debug_panel.dart';
import 'widgets/player_area.dart';
import 'widgets/queue_list.dart';
import 'widgets/transport_controls.dart';

/// Now Playing for both video and audio, built from the device-verified
/// Phase 1 widgets. Phase 3 adds the full-screen video layout.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    final pip = ref.watch(pictureInPictureProvider);
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: coordinator.playQueue,
      builder: (context, queue, _) {
        final current = queue.current;
        return Scaffold(
          appBar: AppBar(title: Text(current?.media.title ?? 'Now playing')),
          body: current == null
              ? const Center(child: Text('Nothing is playing.'))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    PlayerArea(coordinator: coordinator, pip: pip),
                    PlaybackErrorBanner(coordinator: coordinator),
                    TransportControls(coordinator: coordinator),
                    if (current.media.kind == MediaKind.video)
                      BackgroundAudioSwitch(coordinator: coordinator),
                    QueueList(coordinator: coordinator),
                    if (kDebugMode)
                      PlaybackDebugPanel(coordinator: coordinator),
                  ],
                ),
        );
      },
    );
  }
}
