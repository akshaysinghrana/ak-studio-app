import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../playback/application/playback_coordinator.dart';

class PlaybackErrorBanner extends StatelessWidget {
  const PlaybackErrorBanner({super.key, required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: coordinator.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state?.processingState != AudioProcessingState.error) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            state?.errorMessage ?? 'Playback error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      },
    );
  }
}

class TransportControls extends StatelessWidget {
  const TransportControls({
    super.key,
    required this.coordinator,
    this.showSeekBar = true,
  });

  final PlaybackCoordinator coordinator;

  /// False when the screen shows its own [SeekBar].
  final bool showSeekBar;

  void _seekFeedback(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label, textAlign: TextAlign.center),
          duration: const Duration(milliseconds: 700),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: coordinator.controller,
      builder: (context, controller, _) {
        if (controller == null) return const SizedBox.shrink();
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final duration = value.duration;
            final position = value.position > duration
                ? duration
                : value.position;
            final maxMs = duration.inMilliseconds.toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (showSeekBar) ...[
                    Slider(
                      value: maxMs <= 0
                          ? 0
                          : position.inMilliseconds.toDouble().clamp(0, maxMs),
                      max: maxMs <= 0 ? 1 : maxMs,
                      onChanged: maxMs <= 0
                          ? null
                          : (ms) => coordinator.seek(
                              Duration(milliseconds: ms.round()),
                            ),
                      semanticFormatterCallback: (_) =>
                          '${formatDuration(position)} of ${formatDuration(duration)}',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(position)),
                        Text(formatDuration(duration)),
                      ],
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Previous',
                        onPressed: coordinator.skipToPrevious,
                        icon: const Icon(Icons.skip_previous),
                      ),
                      IconButton(
                        tooltip: 'Rewind 10 seconds',
                        onPressed: () {
                          coordinator.rewind();
                          _seekFeedback(context, '-10s');
                        },
                        icon: const Icon(Icons.replay_10),
                      ),
                      IconButton.filled(
                        iconSize: 40,
                        tooltip: value.isPlaying ? 'Pause' : 'Play',
                        onPressed: value.isPlaying
                            ? coordinator.pause
                            : coordinator.play,
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Forward 10 seconds',
                        onPressed: () {
                          coordinator.fastForward();
                          _seekFeedback(context, '+10s');
                        },
                        icon: const Icon(Icons.forward_10),
                      ),
                      IconButton(
                        tooltip: 'Next',
                        onPressed: coordinator.skipToNext,
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// mm:ss, or h:mm:ss for long media.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
