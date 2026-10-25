import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/platform/frame_capture.dart';
import '../../core/platform/picture_in_picture.dart';
import '../playback/application/playback_coordinator.dart';
import '../playback/domain/media_source.dart';
import '../playback/domain/play_queue.dart';

const _screenshotAlbum = 'Media Player Screenshots';

/// Temporary Phase 1 screen proving the media engine on a physical device
/// (spec 8.4). Replaced by the real library/players in Phases 2-3.
class EnginePocScreen extends StatelessWidget {
  const EnginePocScreen({
    super.key,
    required this.coordinator,
    required this.pip,
  });

  final PlaybackCoordinator coordinator;
  final PictureInPicture pip;

  Future<void> _pick(BuildContext context, {required bool replace}) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mp3'],
    );
    final media = [
      for (final f in files)
        if (f.path != null) MediaSource.fromFile(path: f.path!, name: f.name),
    ].nonNulls.toList();
    if (media.isEmpty) return;
    if (replace) {
      await coordinator.playNow(media);
    } else {
      for (final m in media) {
        await coordinator.addToQueue(m);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: pip.isActive,
      builder: (context, inPip, _) =>
          inPip ? _PipView(coordinator: coordinator) : _buildFull(context),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engine proof of concept')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _pick(context, replace: true),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose files'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pick(context, replace: false),
                  icon: const Icon(Icons.queue),
                  label: const Text('Add to queue'),
                ),
              ],
            ),
          ),
          _PlayerArea(coordinator: coordinator, pip: pip),
          _ErrorBanner(coordinator: coordinator),
          _Transport(coordinator: coordinator),
          _BackgroundSetting(coordinator: coordinator),
          _QueueList(coordinator: coordinator),
          if (kDebugMode) _DebugPanel(coordinator: coordinator),
        ],
      ),
    );
  }
}

class _PlayerArea extends StatelessWidget {
  const _PlayerArea({required this.coordinator, required this.pip});

  final PlaybackCoordinator coordinator;
  final PictureInPicture pip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: coordinator.playQueue,
      builder: (context, queue, _) {
        final entry = queue.current;
        if (entry == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Choose an MP4 or MP3 file to start.')),
          );
        }
        return ValueListenableBuilder<VideoPlayerController?>(
          valueListenable: coordinator.controller,
          builder: (context, controller, _) {
            if (controller == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (entry.media.kind == MediaKind.audio) {
              return SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, size: 72),
                    Text(entry.media.title, textAlign: TextAlign.center),
                  ],
                ),
              );
            }
            return _ZoomableVideo(
              // New key per queue entry resets zoom on a new media item.
              key: ValueKey(entry.entryId),
              controller: controller,
              locator: entry.media.locator,
              pip: pip,
            );
          },
        );
      },
    );
  }
}

class _ZoomableVideo extends StatefulWidget {
  const _ZoomableVideo({
    super.key,
    required this.controller,
    required this.locator,
    required this.pip,
  });

  final VideoPlayerController controller;
  final String locator;
  final PictureInPicture pip;

  @override
  State<_ZoomableVideo> createState() => _ZoomableVideoState();
}

class _ZoomableVideoState extends State<_ZoomableVideo> {
  static const _minZoom = 1.0;
  static const _maxZoom = 4.0;
  static const _doubleTapZoom = 2.0;

  final _transform = TransformationController();
  Offset _doubleTapPosition = Offset.zero;
  bool _cover = false;
  bool _capturing = false;
  bool _pipSupported = false;

  @override
  void initState() {
    super.initState();
    widget.pip.isSupported().then((supported) {
      if (mounted) setState(() => _pipSupported = supported);
    });
  }

  Future<void> _enterPip() async {
    final size = widget.controller.value.size;
    final entered = await widget.pip.enter(
      width: size.width > 0 ? size.width.round() : 16,
      height: size.height > 0 ? size.height.round() : 9,
    );
    if (!entered && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Picture-in-picture is unavailable. Check that it is allowed '
            'for this app in system settings.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_transform.value.getMaxScaleOnAxis() > _minZoom) {
      _transform.value = Matrix4.identity();
      return;
    }
    final p = _doubleTapPosition;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -p.dx * (_doubleTapZoom - 1),
        -p.dy * (_doubleTapZoom - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapZoom, _doubleTapZoom, 1, 1);
  }

  Future<void> _captureFrame() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _capturing = true);
    try {
      final path = await const FrameCapture().capture(
        locator: widget.locator,
        position: widget.controller.value.position,
      );
      var saved =
          await Gal.hasAccess(toAlbum: true) ||
          await Gal.requestAccess(toAlbum: true);
      if (saved) {
        try {
          await Gal.putImage(path, album: _screenshotAlbum);
        } on GalException catch (e) {
          saved = false;
          messenger.showSnackBar(
            SnackBar(content: Text('Could not save: ${e.type.message}')),
          );
        }
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Frame saved to "$_screenshotAlbum"'
                : 'Gallery access denied. You can still share the frame.',
          ),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () =>
                SharePlus.instance.share(ShareParams(files: [XFile(path)])),
          ),
        ),
      );
    } on PlatformException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Frame capture failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final aspect = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
    final video = _cover
        ? FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: value.size.width,
              height: value.size.height,
              child: VideoPlayer(widget.controller),
            ),
          )
        : Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: VideoPlayer(widget.controller),
            ),
          );
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapPosition = d.localPosition,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: _minZoom,
                maxScale: _maxZoom,
                // Zero boundary margin keeps the video from being panned off-screen.
                boundaryMargin: EdgeInsets.zero,
                clipBehavior: Clip.hardEdge,
                child: SizedBox.expand(child: video),
              ),
            ),
          ),
        ),
        OverflowBar(
          alignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _transform.value = Matrix4.identity(),
              icon: const Icon(Icons.zoom_out_map),
              label: const Text('Reset zoom'),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _cover = !_cover),
              icon: Icon(_cover ? Icons.fit_screen : Icons.crop),
              label: Text(_cover ? 'Fit' : 'Crop to fill'),
            ),
            TextButton.icon(
              onPressed: _capturing ? null : _captureFrame,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Capture frame'),
            ),
            if (_pipSupported)
              TextButton.icon(
                onPressed: _enterPip,
                icon: const Icon(Icons.picture_in_picture_alt),
                label: const Text('Picture-in-picture'),
              ),
          ],
        ),
      ],
    );
  }
}

/// Minimal layout while in picture-in-picture: video only, no controls.
class _PipView extends StatelessWidget {
  const _PipView({required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: ValueListenableBuilder<VideoPlayerController?>(
        valueListenable: coordinator.controller,
        builder: (context, controller, _) {
          if (controller == null || controller.value.size.isEmpty) {
            return const Center(
              child: Icon(Icons.music_note, color: Colors.white, size: 48),
            );
          }
          return Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.coordinator});

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

class _Transport extends StatelessWidget {
  const _Transport({required this.coordinator});

  final PlaybackCoordinator coordinator;

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
                        '${_fmt(position)} of ${_fmt(duration)}',
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(_fmt(position)), Text(_fmt(duration))],
                  ),
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

class _BackgroundSetting extends StatelessWidget {
  const _BackgroundSetting({required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: coordinator.continueVideoAudioInBackground,
      builder: (context, enabled, _) => SwitchListTile(
        title: const Text('Continue video audio in background'),
        subtitle: const Text(
          'When enabled, video audio can continue while the app is in the '
          'background or the device is locked. The video picture is not '
          'shown on the locked screen.',
        ),
        value: enabled,
        onChanged: (v) => coordinator.continueVideoAudioInBackground.value = v,
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.coordinator});

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

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.coordinator});

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

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
