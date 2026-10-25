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
import '../domain/subtitles.dart';
import '../domain/video_gestures.dart';
import 'widgets/playback_debug_panel.dart';
import 'widgets/player_sheets.dart';
import 'widgets/queue_sheet.dart';
import 'widgets/seek_bar.dart';

enum _MenuAction {
  fit,
  speed,
  subtitles,
  audioTrack,
  sleepTimer,
  rotationLock,
  backgroundAudio,
  pip,
  queue,
  debug,
}

enum _GestureKind { brightness, volume }

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
    _transform.addListener(_onZoomChanged);
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
    // App brightness only applies while the player is open (spec 5.4).
    if (_brightness != null) _screen.setBrightness(null);
    _gestureLabelTimer?.cancel();
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
    _refreshAudioTracks();
  }

  int _audioTrackCount = 0;
  bool _rotationLocked = false;

  Future<void> _refreshAudioTracks() async {
    final c = _listened;
    if (c == null) return;
    // Wait until the engine reports its tracks after initialisation.
    if (!c.value.isInitialized) return;
    final tracks = await _coordinator.audioTracks();
    if (mounted && c == _listened) {
      setState(() => _audioTrackCount = tracks.length);
    }
  }

  bool _lastZoomed = false;

  void _onZoomChanged() {
    // Panning is only enabled while zoomed, leaving vertical swipes at 1x to
    // the brightness/volume gestures.
    if (_zoomed != _lastZoomed && mounted) {
      setState(() => _lastZoomed = _zoomed);
    }
  }

  // ---------------------------------------------------------------------------
  // Brightness / volume swipe gestures (opt-in, spec 5.4)

  double? _brightness;
  double? _volume;
  _GestureKind? _gesture;
  String? _gestureLabel;
  Timer? _gestureLabelTimer;

  Future<void> _onVerticalStart(DragStartDetails d, double width) async {
    final brightnessOn = ref.read(brightnessGestureProvider).value ?? false;
    final volumeOn = ref.read(volumeGestureProvider).value ?? false;
    final left = d.localPosition.dx < width / 2;
    _gesture = left
        ? (brightnessOn ? _GestureKind.brightness : null)
        : (volumeOn ? _GestureKind.volume : null);
    if (_gesture == _GestureKind.brightness) {
      _brightness ??= await _screen.brightness() ?? 0.5;
    } else if (_gesture == _GestureKind.volume) {
      _volume = await _screen.volume();
    }
  }

  void _onVerticalUpdate(DragUpdateDetails d, double height) {
    final delta = -d.delta.dy / (height * 0.8);
    switch (_gesture) {
      case _GestureKind.brightness:
        final v = ((_brightness ?? 0.5) + delta).clamp(0.01, 1.0);
        _brightness = v;
        _screen.setBrightness(v);
        _showGestureLabel('Brightness ${(v * 100).round()}%');
      case _GestureKind.volume:
        final v = ((_volume ?? 0.5) + delta).clamp(0.0, 1.0);
        _volume = v;
        _screen.setVolume(v);
        _showGestureLabel('Volume ${(v * 100).round()}%');
      case null:
        break;
    }
  }

  void _showGestureLabel(String label) {
    _gestureLabelTimer?.cancel();
    setState(() => _gestureLabel = label);
    _gestureLabelTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _gestureLabel = null);
    });
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
        await showQueueSheet(context);
      case _MenuAction.speed:
        await showSpeedSheet(context, _coordinator);
      case _MenuAction.subtitles:
        await showSubtitleSheet(context, ref);
      case _MenuAction.audioTrack:
        await showAudioTrackSheet(context, _coordinator);
      case _MenuAction.sleepTimer:
        await showSleepTimerSheet(context, _coordinator);
      case _MenuAction.rotationLock:
        await _toggleRotationLock();
      case _MenuAction.debug:
        await showModalBottomSheet<void>(
          context: context,
          builder: (_) => SingleChildScrollView(
            child: PlaybackDebugPanel(coordinator: _coordinator),
          ),
        );
    }
  }

  Future<void> _toggleRotationLock() async {
    if (_rotationLocked) {
      await SystemChrome.setPreferredOrientations(
        _fullscreen
            ? const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : const [],
      );
    } else {
      final landscape =
          MediaQuery.orientationOf(context) == Orientation.landscape;
      await SystemChrome.setPreferredOrientations([
        landscape
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.portraitUp,
      ]);
    }
    if (mounted) setState(() => _rotationLocked = !_rotationLocked);
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
                if (controller != null) _captions(controller),
                if (_seekLabel != null) _seekFeedback(),
                if (_gestureLabel != null) _gestureFeedback(),
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
        final gestures =
            !_locked &&
            !_zoomed &&
            ((ref.watch(brightnessGestureProvider).value ?? false) ||
                (ref.watch(volumeGestureProvider).value ?? false));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _locked ? () => _showControls() : _toggleControls,
          onDoubleTapDown: (d) => _doubleTapPosition = d.localPosition,
          onDoubleTap: () => _onDoubleTap(constraints.maxWidth),
          onVerticalDragStart: gestures
              ? (d) => _onVerticalStart(d, constraints.maxWidth)
              : null,
          onVerticalDragUpdate: gestures
              ? (d) => _onVerticalUpdate(d, constraints.maxHeight)
              : null,
          onVerticalDragEnd: gestures ? (_) => _gesture = null : null,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: _minZoom,
            maxScale: _maxZoom,
            panEnabled: !_locked && _zoomed,
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

  Widget _captions(VideoPlayerController controller) {
    final size = ref.watch(subtitleSizeProvider).value ?? SubtitleSize.medium;
    final fontSize = switch (size) {
      SubtitleSize.small => 14.0,
      SubtitleSize.medium => 18.0,
      SubtitleSize.large => 24.0,
    };
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, v, _) => Positioned(
        left: 24,
        right: 24,
        bottom: _controlsVisible && !_locked ? 140 : 32,
        child: IgnorePointer(
          child: ClosedCaption(
            text: v.caption.text,
            textStyle: TextStyle(fontSize: fontSize, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _gestureFeedback() {
    return Align(
      alignment: const Alignment(0, -0.5),
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
                _gestureLabel!,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
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
              PopupMenuItem(
                value: _MenuAction.speed,
                child: Text(
                  'Playback speed (${speedLabel(_coordinator.speed.value)})',
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.subtitles,
                child: Text(
                  _coordinator.subtitles.value == null
                      ? 'Subtitles'
                      : 'Subtitles (on)',
                ),
              ),
              if (_audioTrackCount > 1)
                const PopupMenuItem(
                  value: _MenuAction.audioTrack,
                  child: Text('Audio track'),
                ),
              PopupMenuItem(
                value: _MenuAction.sleepTimer,
                child: Text(
                  _coordinator.sleepTimer.value == null
                      ? 'Sleep timer'
                      : 'Sleep timer (on)',
                ),
              ),
              CheckedPopupMenuItem(
                value: _MenuAction.rotationLock,
                checked: _rotationLocked,
                child: const Text('Lock rotation'),
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
