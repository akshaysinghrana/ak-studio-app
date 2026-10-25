import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../playback/domain/media_source.dart';
import '../../playback/application/playback_coordinator.dart';
import '../../playback/domain/play_queue.dart';

/// Compact player above the navigation bar whenever an item is active
/// (spec 3). Tapping it opens Now Playing.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: coordinator.playQueue,
      builder: (context, queue, _) {
        final current = queue.current;
        if (current == null) return const SizedBox.shrink();
        final isVideo = current.media.kind == MediaKind.video;
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniProgress(coordinator: coordinator),
              SizedBox(
                height: AppTokens.miniPlayerHeight,
                child: ListTile(
                  onTap: () => context.push(Routes.player),
                  leading: Icon(isVideo ? Icons.movie : Icons.music_note),
                  title: Text(
                    current.media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    current.media.artist ?? (isVideo ? 'Video' : 'Audio'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PlayPause(coordinator: coordinator),
                      IconButton(
                        tooltip: 'Next',
                        onPressed: queue.hasNext
                            ? coordinator.skipToNext
                            : null,
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayPause extends StatelessWidget {
  const _PlayPause({required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: coordinator.controller,
      builder: (context, controller, _) {
        if (controller == null) {
          return const SizedBox.square(
            dimension: AppTokens.minTouchTarget,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) => IconButton(
            tooltip: value.isPlaying ? 'Pause' : 'Play',
            onPressed: value.isPlaying ? coordinator.pause : coordinator.play,
            icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        );
      },
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: coordinator.controller,
      builder: (context, controller, _) {
        if (controller == null) return const SizedBox(height: 2);
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, v, _) {
            final total = v.duration.inMilliseconds;
            return ExcludeSemantics(
              child: LinearProgressIndicator(
                minHeight: 2,
                value: total <= 0
                    ? 0
                    : (v.position.inMilliseconds / total).clamp(0.0, 1.0),
              ),
            );
          },
        );
      },
    );
  }
}
