import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../app/providers.dart';
import '../../../core/platform/screen_control.dart';
import '../../playback/application/playback_coordinator.dart';
import '../../playback/domain/play_queue.dart';
import '../application/frame_capture_action.dart';
import '../domain/video_gestures.dart';
import 'widgets/playback_debug_panel.dart';
import 'widgets/queue_sheet.dart';
import 'widgets/seek_bar.dart';

enum _MenuAction { fit, backgroundAudio, pip, queue, debug }

/// Full-screen video player (spec 5): auto-hiding controls, ±10 s buttons and
/// double-tap zones, pinch zoom/pan with arbitration, fit modes, controls
/// lock, fullscreen/orientation, frame capture and PiP.
class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  static const _hideAfter = Duration(seconds: 3);
  static const _minZoom = 1.0;
  static const _maxZoom = 4.0;
  static const _doubleTapZoom = 2.0;

  final _transform = TransformationController();
  final _screen = const ScreenControl();
  late final PlaybackCoordinator _coordinator;

  bool _controlsVisible = true;
  bool _locked = false;
  bool _fullscreen = false;
  bool _pipSupported = false;
  VideoFit _fit = VideoFit.contain;
  Timer? _hideTimer;
  Timer? _seekLabelTimer;
  String? _seekLabel;
  bool _seekLabelLeft = true;
  Offset _doubleTapPosition = Offset.zero;
  String? _entryId;
  VideoPlayerController? _listened;
  bool _keepingScreenOn = false;

  @override
  void initState() {
    super.initState();
    _coordinator = ref.read(coordinatorProvider);
    _coordinator.controller.addListener(_onEngineChanged);
    _onEngineChanged();
    ref.read(pictureInPictureProvider).isSupported().then((s) {
      if (mounted) setState(() => _pipSupported = s);
    });
  }

  @override
  void dispose() {
    _coordinator.controller.removeListener(_onEngineChanged);
    _listened?.removeListener(_onValueChanged);
    _hideTimer?.cancel();
    _seekLabelTimer?.cancel();
    _transform.dispose();
    _screen.keepOn(false);
    if (_fullscreen) _restoreSystemUi();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Engine listeners: keep the screen on only while video plays.

  void _onEngineChanged() {
    _listened?.removeListener(_onValueChanged);
    _listened = _coordinator.controller.value;
    _listened?.addListener(_onValueChanged);
    _onValueChanged();
  }

  bool _wasPlaying = false;

  void _onValueChanged() {
    final playing = _listened?.value.isPlaying ?? false;
    if (playing != _keepingScreenOn) {
      _keepingScreenOn = playing;
      _screen.keepOn(playing);
    }
    if (playing != _wasPlaying) {
      _wasPlaying = playing;
      // Controls stay visible while paused and auto-hide while playing.
      if (playing) {
        _scheduleHide();
      } else {
        _showControls(autoHide: false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Controls visibility

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!(_listened?.value.isPlaying ?? false)) return;
    _hideTimer = Timer(_hideAfter, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showControls({bool autoHide = true}) {
    if (!mounted) return;
    setState(() => _controlsVisible = true);
    if (autoHide) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  // ---------------------------------------------------------------------------
  // Gestures

  bool get _zoomed => _transform.value.getMaxScaleOnAxis() > _minZoom + 0.01;

  void _onDoubleTap(double width) {
    if (_locked) return;
    switch (doubleTapAction(
      x: _doubleTapPosition.dx,
      width: width,
      zoomed: _zoomed,
    )) {
      case DoubleTapAction.rewind:
        _seekBy(forward: false);
      case DoubleTapAction.forward:
        _seekBy(forward: true);
      case DoubleTapAction.resetZoom:
        _transform.value = Matrix4.identity();
      case DoubleTapAction.zoomIn:
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
  }

  void _seekBy({required bool forward}) {
    forward ? _coordinator.fastForward() : _coordinator.rewind();
    _seekLabelTimer?.cancel();
    setState(() {
      _seekLabel = forward ? '+10s' : '-10s';
      _seekLabelLeft = !forward;
    });
    _seekLabelTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekLabel = null);
    });
    if (_controlsVisible) _scheduleHide();
  }

  // ---------------------------------------------------------------------------
  // Fullscreen / orientation

  Future<void> _toggleFullscreen() async {
    final value = _listened?.value;
    if (!_fullscreen) {
      final landscape = (value?.aspectRatio ?? 16 / 9) >= 1;
      await SystemChrome.setPreferredOrientations(
        landscape
            ? const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : const [DeviceOrientation.portraitUp],
      );
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restoreSystemUi();
    }
    if (mounted) setState(() => _fullscreen = !_fullscreen);
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setPreferredOrientations(const []);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ---------------------------------------------------------------------------
  // Menu

  Future<void> _onMenu(_MenuAction action) async {
    final c = _listened;
    switch (action) {
      case _MenuAction.fit:
        await _chooseFit();
      case _MenuAction.backgroundAudio:
        final setting = _coordinator.continueVideoAudioInBackground;
        setting.value = !setting.value;
      case _MenuAction.pip:
        final size = c?.value.size ?? Size.zero;
        final ok = await ref
            .read(pictureInPictureProvider)
            .enter(
              width: size.width > 0 ? size.width.round() : 16,
              height: size.height > 0 ? size.height.round() : 9,
            );
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Picture-in-picture is unavailable. Check that it is allowed '
                'for this app in system settings.',
              ),
            ),
          );
        }
      case _MenuAction.queue:
        await showQueueSheet(context, _coordinator);
      case _MenuAction.debug:
        await showModalBottomSheet<void>(
          context: context,
          builder: (_) => SingleChildScrollView(
            child: PlaybackDebugPanel(coordinator: _coordinator),
          ),
        );
    }
  }

  Future<void> _chooseFit() async {
    const labels = {
      VideoFit.contain: 'Fit (show whole frame)',
      VideoFit.cover: 'Crop to fill',
      VideoFit.stretch: 'Stretch',
    };
    final picked = await showModalBottomSheet<VideoFit>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<VideoFit>(
          groupValue: _fit,
          onChanged: (v) => Navigator.pop(context, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in VideoFit.values)
                RadioListTile<VideoFit>(value: f, title: Text(labels[f]!)),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _fit = picked);
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: _coordinator.playQueue,
      builder: (context, queue, _) {
        final entry = queue.current;
        if (entry?.entryId != _entryId) {
          // Reset zoom on a new media item, not on progress updates.
          _entryId = entry?.entryId;
          _transform.value = Matrix4.identity();
        }
        return ValueListenableBuilder<VideoPlayerController?>(
          valueListenable: _coordinator.controller,
          builder: (context, controller, _) => Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                _surface(controller),
                _statusLayer(controller),
                if (_seekLabel != null) _seekFeedback(),
                if (!_locked)
                  _controls(context, controller, entry?.media.title ?? '')
                else
                  _lockedOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _surface(VideoPlayerController? controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget video = const SizedBox.expand();
        if (controller != null && controller.value.isInitialized) {
          final v = controller.value;
          final player = VideoPlayer(controller);
          video = switch (_fit) {
            VideoFit.contain => Center(
              child: AspectRatio(aspectRatio: v.aspectRatio, child: player),
            ),
            VideoFit.cover => FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: v.size.width,
                height: v.size.height,
                child: player,
              ),
            ),
            VideoFit.stretch => SizedBox.expand(child: player),
          };
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _locked ? () => _showControls() : _toggleControls,
          onDoubleTapDown: (d) => _doubleTapPosition = d.localPosition,
          onDoubleTap: () => _onDoubleTap(constraints.maxWidth),
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: _minZoom,
            maxScale: _maxZoom,
            panEnabled: !_locked,
            scaleEnabled: !_locked,
            // Zero margin keeps the video from being panned off-screen.
            boundaryMargin: EdgeInsets.zero,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.expand(child: video),
          ),
        );
      },
    );
  }

  Widget _statusLayer(VideoPlayerController? controller) {
    return StreamBuilder<PlaybackState>(
      stream: _coordinator.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state?.processingState == AudioProcessingState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state?.errorMessage ?? 'This video cannot be played.',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, v, _) => v.isBuffering || !v.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _seekFeedback() {
    return Align(
      alignment: _seekLabelLeft
          ? const Alignment(-0.6, 0)
          : const Alignment(0.6, 0),
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _seekLabel!,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedOverlay() {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton.filledTonal(
                tooltip: 'Unlock controls',
                iconSize: 32,
                onPressed: () {
                  setState(() => _locked = false);
                  _showControls();
                },
                icon: const Icon(Icons.lock),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(
    BuildContext context,
    VideoPlayerController? controller,
    String title,
  ) {
    const fg = Colors.white;
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black54],
              stops: [0, 0.5, 1],
            ),
          ),
          child: SafeArea(
            child: IconButtonTheme(
              data: IconButtonThemeData(
                style: IconButton.styleFrom(foregroundColor: fg),
              ),
              child: Column(
                children: [
                  _topBar(context, controller, title),
                  const Spacer(),
                  if (controller != null) _centerRow(controller),
                  const Spacer(),
                  if (controller != null) _bottomBar(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(
    BuildContext context,
    VideoPlayerController? controller,
    String title,
  ) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        if (controller != null)
          IconButton(
            tooltip: 'Capture frame',
            onPressed: () {
              final entry = _coordinator.playQueue.value.current;
              if (entry == null) return;
              _showControls();
              captureAndSaveFrame(
                context,
                locator: entry.media.locator,
                position: controller.value.position,
              );
            },
            icon: const Icon(Icons.photo_camera_outlined),
          ),
        ValueListenableBuilder<bool>(
          valueListenable: _coordinator.continueVideoAudioInBackground,
          builder: (context, background, _) => PopupMenuButton<_MenuAction>(
            tooltip: 'More options',
            iconColor: Colors.white,
            onOpened: () => _hideTimer?.cancel(),
            onCanceled: _scheduleHide,
            onSelected: (a) {
              _onMenu(a);
              _scheduleHide();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _MenuAction.fit,
                child: Text('Aspect ratio'),
              ),
              CheckedPopupMenuItem(
                value: _MenuAction.backgroundAudio,
                checked: background,
                child: const Text('Continue audio in background'),
              ),
              if (_pipSupported)
                const PopupMenuItem(
                  value: _MenuAction.pip,
                  child: Text('Picture-in-picture'),
                ),
              const PopupMenuItem(
                value: _MenuAction.queue,
                child: Text('Queue'),
              ),
              if (kDebugMode)
                const PopupMenuItem(
                  value: _MenuAction.debug,
                  child: Text('Debug info'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _centerRow(VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, v, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Rewind 10 seconds',
            iconSize: 40,
            onPressed: () => _seekBy(forward: false),
            icon: const Icon(Icons.replay_10),
          ),
          IconButton.filled(
            tooltip: v.isPlaying ? 'Pause' : 'Play',
            iconSize: 56,
            onPressed: () {
              v.isPlaying ? _coordinator.pause() : _coordinator.play();
              _showControls(autoHide: !v.isPlaying);
            },
            icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Forward 10 seconds',
            iconSize: 40,
            onPressed: () => _seekBy(forward: true),
            icon: const Icon(Icons.forward_10),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(VideoPlayerController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SeekBar(
          controller: controller,
          foreground: Colors.white,
          onInteraction: _scheduleHide,
          onSeek: _coordinator.seek,
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous',
              onPressed: _coordinator.skipToPrevious,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: _coordinator.skipToNext,
              icon: const Icon(Icons.skip_next),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Lock controls',
              onPressed: () {
                _hideTimer?.cancel();
                setState(() {
                  _locked = true;
                  _controlsVisible = false;
                });
              },
              icon: const Icon(Icons.lock_open),
            ),
            if (_zoomed)
              IconButton(
                tooltip: 'Reset zoom',
                onPressed: () =>
                    setState(() => _transform.value = Matrix4.identity()),
                icon: const Icon(Icons.zoom_out_map),
              ),
            IconButton(
              tooltip: _fullscreen ? 'Exit fullscreen' : 'Fullscreen',
              onPressed: _toggleFullscreen,
              icon: Icon(
                _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
