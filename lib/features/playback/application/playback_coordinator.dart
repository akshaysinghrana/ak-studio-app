import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import '../domain/background_policy.dart';
import '../domain/media_source.dart';
import '../domain/play_queue.dart';
import '../domain/seek.dart';

/// Single source of truth for the current media, queue, position, play intent
/// and background state (spec 8.3, 10.4).
///
/// Phase 1 engine: one ExoPlayer instance per item via `video_player`, used for
/// both MP4 and MP3, so there is never a second audible engine and no
/// foreground/background handoff. See docs/adr/0001-media-engine.md.
///
/// UI, notification, lock screen and headset buttons all call the
/// [BaseAudioHandler] overrides below.
class PlaybackCoordinator extends BaseAudioHandler with SeekHandler {
  PlaybackCoordinator._();

  static Future<PlaybackCoordinator> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    final coordinator = await AudioService.init(
      builder: PlaybackCoordinator._,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.akshayrana.video_music_app.playback',
        androidNotificationChannelName: 'Playback',
        // Keep the service in the foreground while paused so resuming from
        // the lock screen cannot hit Android 12+ background-start limits.
        androidStopForegroundOnPause: false,
        fastForwardInterval: kSeekStep,
        rewindInterval: kSeekStep,
      ),
    );
    coordinator._attach(session);
    return coordinator;
  }

  /// The active engine for the current item; null while loading or idle.
  final ValueNotifier<VideoPlayerController?> controller = ValueNotifier(null);

  /// Spec 8.1: "Continue video audio in background". Default off.
  final ValueNotifier<bool> continueVideoAudioInBackground = ValueNotifier(
    false,
  );

  final ValueNotifier<bool> inBackground = ValueNotifier(false);
  final ValueNotifier<PlayQueue> playQueue = ValueNotifier(
    const PlayQueue.empty(),
  );

  /// Recent coordinator events, shown only in debug builds.
  final ValueNotifier<List<String>> debugEvents = ValueNotifier(const []);

  // TODO(phase-2): persist to Drift; in-memory only for the Phase 1 POC.
  final Map<String, Duration> _savedPositions = {};

  late final AppLifecycleListener _lifecycle;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  int _loadGeneration = 0;
  int _entryCounter = 0;
  bool _completionHandled = false;

  PlayQueue get _queue => playQueue.value;

  void _attach(AudioSession session) {
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
    // ExoPlayer handles audio focus itself (calls, other players). Unplugging
    // headphones / Bluetooth disconnect must pause and not auto-resume.
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        _log('becoming noisy -> pause');
        pause();
      }),
    );
    continueVideoAudioInBackground.addListener(_applyBackgroundPolicy);
  }

  // ---------------------------------------------------------------------------
  // Queue commands

  Future<void> playNow(List<MediaSource> media) async {
    if (media.isEmpty) return;
    _setQueue(PlayQueue.of(media.map(_newEntry).toList()));
    await _loadCurrent(autoplay: true);
  }

  Future<void> addToQueue(MediaSource media) async {
    final wasEmpty = _queue.isEmpty;
    _setQueue(_queue.append(_newEntry(media)));
    if (wasEmpty) await _loadCurrent(autoplay: false);
  }

  Future<void> playNextInQueue(MediaSource media) async {
    final wasEmpty = _queue.isEmpty;
    _setQueue(_queue.playNext(_newEntry(media)));
    if (wasEmpty) await _loadCurrent(autoplay: false);
  }

  // ---------------------------------------------------------------------------
  // BaseAudioHandler overrides (UI + system media controls)

  @override
  Future<void> play() async {
    final c = controller.value;
    if (c == null) return;
    if (c.value.isCompleted) await c.seekTo(Duration.zero);
    await c.play();
    _log('play');
  }

  @override
  Future<void> pause() async {
    final c = controller.value;
    if (c == null) return;
    await c.pause();
    _savePosition();
    _log('pause @ ${_fmt(c.value.position)}');
  }

  @override
  Future<void> seek(Duration position) async {
    final c = controller.value;
    if (c == null) return;
    final target = clampPosition(position, c.value.duration);
    await c.seekTo(target);
    _completionHandled = false;
    _broadcast(force: true, position: target);
  }

  @override
  Future<void> fastForward() => _seekBy(kSeekStep);

  @override
  Future<void> rewind() => _seekBy(-kSeekStep);

  @override
  Future<void> skipToNext() async {
    if (!_queue.hasNext) return;
    _savePosition();
    _setQueue(_queue.next());
    await _loadCurrent(autoplay: _autoplayAllowed());
  }

  @override
  Future<void> skipToPrevious() async {
    final c = controller.value;
    final position = c?.value.position ?? Duration.zero;
    if (_queue.previousAction(position) == PreviousAction.restartCurrent) {
      await seek(Duration.zero);
      return;
    }
    _savePosition();
    _setQueue(_queue.previous());
    await _loadCurrent(autoplay: _autoplayAllowed());
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.entries.length) return;
    _savePosition();
    _setQueue(_queue.jumpTo(index));
    await _loadCurrent(autoplay: true);
  }

  @override
  Future<void> stop() async {
    _savePosition();
    _loadGeneration++;
    await _disposeController();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    _log('stop');
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() => stop();

  // ---------------------------------------------------------------------------
  // Background policy (spec 8.2)

  void _onLifecycleChanged(AppLifecycleState state) {
    final background =
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
    if (background == inBackground.value) return;
    inBackground.value = background;
    _log(background ? 'app -> background' : 'app -> foreground');
    // Returning to the foreground never auto-resumes a policy pause.
    if (background) _applyBackgroundPolicy();
  }

  void _applyBackgroundPolicy() {
    final entry = _queue.current;
    final c = controller.value;
    if (!inBackground.value || entry == null || c == null) return;
    if (!c.value.isPlaying) return;
    final action = backgroundActionFor(
      kind: entry.media.kind,
      continueVideoAudioInBackground: continueVideoAudioInBackground.value,
    );
    if (action == BackgroundAction.pauseAndSavePosition) {
      _log('background policy: pause video');
      pause();
    } else {
      _log('background policy: keep playing ${entry.media.kind.name}');
    }
  }

  bool _autoplayAllowed() {
    final entry = _queue.current;
    if (!inBackground.value || entry == null) return true;
    return backgroundActionFor(
          kind: entry.media.kind,
          continueVideoAudioInBackground: continueVideoAudioInBackground.value,
        ) ==
        BackgroundAction.keepPlaying;
  }

  // ---------------------------------------------------------------------------
  // Engine lifecycle

  Future<void> _loadCurrent({required bool autoplay}) async {
    final entry = _queue.current;
    if (entry == null) return;
    final generation = ++_loadGeneration;
    // Dispose the previous engine before creating the next one so two engines
    // are never audible at the same time.
    await _disposeController();
    if (generation != _loadGeneration) return;

    mediaItem.add(_toMediaItem(entry));
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.loading,
        playing: false,
        queueIndex: _queue.currentIndex,
        errorMessage: null,
        errorCode: null,
      ),
    );

    final media = entry.media;
    final options = VideoPlayerOptions(allowBackgroundPlayback: true);
    final c = media.locator.startsWith('content://')
        ? VideoPlayerController.contentUri(
            Uri.parse(media.locator),
            videoPlayerOptions: options,
          )
        : VideoPlayerController.file(
            File(media.locator),
            videoPlayerOptions: options,
          );
    try {
      await c.initialize();
    } catch (e) {
      await c.dispose();
      if (generation != _loadGeneration) return;
      _log('load failed: $e');
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage:
              'Cannot play "${media.title}". The file may be '
              'missing, corrupt or use an unsupported codec.',
        ),
      );
      return;
    }
    if (generation != _loadGeneration) {
      await c.dispose();
      return;
    }

    _completionHandled = false;
    mediaItem.add(_toMediaItem(entry, duration: c.value.duration));
    final saved = _savedPositions[media.id];
    if (saved != null && saved < c.value.duration - kSeekStep) {
      await c.seekTo(saved);
    }
    c.addListener(_onControllerChanged);
    controller.value = c;
    _log('loaded ${media.kind.name} "${media.title}"');
    if (autoplay) {
      await c.play();
    } else {
      _broadcast(force: true);
    }
  }

  Future<void> _disposeController() async {
    final old = controller.value;
    if (old == null) return;
    controller.value = null;
    old.removeListener(_onControllerChanged);
    await old.dispose();
  }

  bool? _lastPlaying;
  bool? _lastBuffering;

  void _onControllerChanged() {
    final c = controller.value;
    if (c == null) return;
    final v = c.value;
    if (v.hasError) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage: v.errorDescription,
        ),
      );
      return;
    }
    if (v.isCompleted && !_completionHandled) {
      _completionHandled = true;
      _onCompleted();
      return;
    }
    // Only broadcast on state changes; audio_service extrapolates position.
    if (v.isPlaying != _lastPlaying || v.isBuffering != _lastBuffering) {
      _broadcast();
    }
  }

  Future<void> _onCompleted() async {
    _savedPositions.remove(_queue.current?.media.id);
    if (_queue.hasNext) {
      _setQueue(_queue.next());
      await _loadCurrent(autoplay: _autoplayAllowed());
    } else {
      // TODO(phase-4): repeat-one / repeat-all / shuffle.
      _broadcast(force: true, completed: true);
      _log('queue finished');
    }
  }

  void _broadcast({
    bool force = false,
    Duration? position,
    bool completed = false,
  }) {
    final c = controller.value;
    if (c == null) return;
    final v = c.value;
    _lastPlaying = v.isPlaying;
    _lastBuffering = v.isBuffering;
    final playing = v.isPlaying && !completed;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [1, 2, 3],
        processingState: completed
            ? AudioProcessingState.completed
            : v.isBuffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
        playing: playing,
        updatePosition: position ?? v.position,
        bufferedPosition: v.buffered.isEmpty
            ? Duration.zero
            : v.buffered.last.end,
        speed: v.playbackSpeed,
        queueIndex: _queue.currentIndex,
      ),
    );
  }

  Future<void> _seekBy(Duration delta) async {
    final c = controller.value;
    if (c == null) return;
    await seek(seekBy(c.value.position, delta, c.value.duration));
  }

  void _savePosition() {
    final entry = _queue.current;
    final c = controller.value;
    if (entry == null || c == null) return;
    _savedPositions[entry.media.id] = c.value.position;
  }

  void _setQueue(PlayQueue next) {
    playQueue.value = next;
    queue.add(next.entries.map(_toMediaItem).toList());
  }

  QueueEntry _newEntry(MediaSource media) =>
      QueueEntry(entryId: 'q${_entryCounter++}', media: media);

  MediaItem _toMediaItem(QueueEntry entry, {Duration? duration}) => MediaItem(
    id: entry.entryId,
    title: entry.media.title,
    // Never fabricate artist/album metadata (spec 6.1).
    album: null,
    artist: null,
    duration: duration,
    extras: {'kind': entry.media.kind.name},
  );

  void _log(String event) {
    if (!kDebugMode) return;
    final now = DateTime.now().toIso8601String().substring(11, 19);
    final next = ['$now $event', ...debugEvents.value];
    debugEvents.value = next.take(30).toList();
    debugPrint('[playback] $event');
  }

  static String _fmt(Duration d) => d.toString().split('.').first;

  @visibleForTesting
  Future<void> dispose() async {
    _lifecycle.dispose();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _disposeController();
  }
}
