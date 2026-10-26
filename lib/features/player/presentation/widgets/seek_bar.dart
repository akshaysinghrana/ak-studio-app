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
            LayoutBuilder(
              builder: (context, c) {
                final fraction = maxMs <= 0
                    ? 0.0
                    : (positionMs / maxMs).clamp(0.0, 1.0);
                return Stack(
                  clipBehavior: Clip.none,
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
                    // Time bubble above the thumb while dragging.
                    if (_dragMs != null)
                      Positioned(
                        left: (24 + fraction * (c.maxWidth - 48) - 36).clamp(
                          0,
                          c.maxWidth - 72,
                        ),
                        top: -30,
                        child: IgnorePointer(
                          child: Container(
                            width: 72,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .inverseSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              formatDuration(shown),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onInverseSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
