import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/widgets/media_tile.dart';
import '../../playback/application/playback_coordinator.dart';
import '../../playback/domain/media_source.dart';
import '../../playback/domain/play_queue.dart';
import 'widgets/transport_controls.dart';

/// Floating player above the navigation bar whenever an item is active
/// (spec 3). Tap opens Now Playing; swipe left/right for next/previous while
/// playing. Sliding the strip away while paused dismisses it.
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
        return ValueListenableBuilder<VideoPlayerController?>(
          valueListenable: coordinator.controller,
          builder: (context, controller, _) {
            if (controller == null) {
              return _strip(
                context: context,
                ref: ref,
                coordinator: coordinator,
                queue: queue,
                playing: true,
              );
            }
            return ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) => _strip(
                context: context,
                ref: ref,
                coordinator: coordinator,
                queue: queue,
                playing: value.isPlaying,
              ),
            );
          },
        );
      },
    );
  }

  Widget _strip({
    required BuildContext context,
    required WidgetRef ref,
    required PlaybackCoordinator coordinator,
    required PlayQueue queue,
    required bool playing,
  }) {
    final current = queue.current!;
    final media = current.media;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final thumb = ref.watch(thumbnailProvider(media.locator)).value;
    final card = Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.player),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: AppTokens.miniPlayerHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: media.kind == MediaKind.video ? 72 : 48,
                        height: 48,
                        child: ThumbnailImage(
                          path: thumb,
                          seed: media.title,
                          kind: media.kind,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            media.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            media.artist ??
                                (media.kind == MediaKind.video
                                    ? 'Video'
                                    : 'Music'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PlayPause(coordinator: coordinator),
                    IconButton(
                      tooltip: 'Next',
                      onPressed: queue.hasNext ? coordinator.skipToNext : null,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              _MiniProgress(coordinator: coordinator),
            ],
          ),
        ),
      ),
    );

    if (!playing) {
      return Dismissible(
        key: ValueKey('mini-${current.entryId}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) {
          HapticFeedback.selectionClick();
          coordinator.dismissPlayback();
        },
        background: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radiusM),
            ),
            child: Center(
              child: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        child: card,
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300 && queue.hasNext) {
          HapticFeedback.selectionClick();
          coordinator.skipToNext();
        } else if (v > 300) {
          HapticFeedback.selectionClick();
          coordinator.skipToPrevious();
        }
      },
      child: card,
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
            icon: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brand,
              ),
              child: PlayPauseIcon(
                playing: value.isPlaying,
                color: Colors.white,
                size: 24,
              ),
            ),
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
        if (controller == null) return const SizedBox(height: 3);
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, v, _) {
            final total = v.duration.inMilliseconds;
            final f = total <= 0
                ? 0.0
                : (v.position.inMilliseconds / total).clamp(0.0, 1.0);
            return ExcludeSemantics(
              child: SizedBox(
                height: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: f,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: AppColors.brand),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
