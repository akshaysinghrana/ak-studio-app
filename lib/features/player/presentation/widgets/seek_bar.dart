import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'transport_controls.dart';

/// Seek bar with elapsed/total time. Dragging previews the position and
/// seeks once on release, so a drag does not issue dozens of seeks.
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.controller,
    required this.onSeek,
    this.onInteraction,
    this.foreground,
  });

  final VideoPlayerController controller;
  final ValueChanged<Duration> onSeek;

  /// Called on any touch, e.g. to keep auto-hiding controls visible.
  final VoidCallback? onInteraction;
  final Color? foreground;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final maxMs = duration.inMilliseconds.toDouble();
        final positionMs =
            _dragMs ??
            value.position.inMilliseconds.toDouble().clamp(
              0,
              maxMs > 0 ? maxMs : 0,
            );
        final shown = Duration(milliseconds: positionMs.round());
        final style = TextStyle(color: widget.foreground);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: maxMs <= 0 ? 0 : positionMs.clamp(0, maxMs),
              max: maxMs <= 0 ? 1 : maxMs,
              onChangeStart: (_) => widget.onInteraction?.call(),
              onChanged: maxMs <= 0
                  ? null
                  : (ms) {
                      widget.onInteraction?.call();
                      setState(() => _dragMs = ms);
                    },
              onChangeEnd: maxMs <= 0
                  ? null
                  : (ms) {
                      widget.onSeek(Duration(milliseconds: ms.round()));
                      setState(() => _dragMs = null);
                    },
              semanticFormatterCallback: (_) =>
                  '${formatDuration(shown)} of ${formatDuration(duration)}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(shown), style: style),
                  Text(formatDuration(duration), style: style),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
