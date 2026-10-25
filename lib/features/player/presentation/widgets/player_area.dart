import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/platform/frame_capture.dart';
import '../../../../core/platform/picture_in_picture.dart';
import '../../../playback/application/playback_coordinator.dart';
import '../../../playback/domain/media_source.dart';
import '../../../playback/domain/play_queue.dart';

const screenshotAlbum = 'Media Player Screenshots';

class PlayerArea extends StatelessWidget {
  const PlayerArea({super.key, required this.coordinator, required this.pip});

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
            return ZoomableVideo(
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

class ZoomableVideo extends StatefulWidget {
  const ZoomableVideo({
    super.key,
    required this.controller,
    required this.locator,
    required this.pip,
  });

  final VideoPlayerController controller;
  final String locator;
  final PictureInPicture pip;

  @override
  State<ZoomableVideo> createState() => _ZoomableVideoState();
}

class _ZoomableVideoState extends State<ZoomableVideo> {
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
          await Gal.putImage(path, album: screenshotAlbum);
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
                ? 'Frame saved to "$screenshotAlbum"'
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
class PipView extends StatelessWidget {
  const PipView({super.key, required this.coordinator});

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
