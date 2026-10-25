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
import '../../player/domain/subtitles.dart';
import '../domain/seek.dart';
import '../domain/sleep_timer.dart';
import 'playback_progress_store.dart';
import 'queue_store.dart';

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
  PlaybackCoordinator._(
    this._progressStore,
    this._queueStore,
    this._onLoadError,
    this._artwork,
  );

  /// [onLoadError] lets the library re-check a file that failed to open
  /// (missing, revoked grant or corrupt).
  static Future<PlaybackCoordinator> init({
    PlaybackProgressStore? progressStore,
    QueueStore? queueStore,
    void Function(MediaSource media)? onLoadError,
    Future<Uri?> Function(MediaSource media)? artworkFor,
  }) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    final coordinator = await AudioService.init(
      builder: () => PlaybackCoordinator._(
        progressStore ?? InMemoryPlaybackProgressStore(),
        queueStore ?? InMemoryQueueStore(),
        onLoadError,
        artworkFor,
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.akshayrana.video_music_app.playback',
        androidNotificationChannelName: 'Playback',
        // Monochrome status-bar glyph (android/app/src/main/res/drawable).
        androidNotificationIcon: 'drawable/ic_stat_player',
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

  /// Playback speed, applied to every item until changed (spec 4.2).
  final ValueNotifier<double> speed = ValueNotifier(1.0);

  final ValueNotifier<SleepTimer?> sleepTimer = ValueNotifier(null);
  Timer? _sleepTimer;

  /// External subtitles for the current item, if any.
  final ValueNotifier<SubtitleTrack?> subtitles = ValueNotifier(null);
  final ValueNotifier<Duration> subtitleOffset = ValueNotifier(Duration.zero);
  final Map<String, SubtitleTrack> _subtitlesByMedia = {};

  /// Recent coordinator events, shown only in debug builds.
  final ValueNotifier<List<String>> debugEvents = ValueNotifier(const []);

  final PlaybackProgressStore _progressStore;
  final QueueStore _queueStore;
  Timer? _queueSaveTimer;
  final void Function(MediaSource media)? _onLoadError;

  /// Cover art / thumbnail for the system media session, if any.
  final Future<Uri?> Function(MediaSource media)? _artwork;
  final Map<String, Uri?> _artworkCache = {};
  Timer? _progressTimer;

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
    continueVideoAudioInBackground.addListener(() {
      _log(
        'setting continueVideoAudioInBackground='
        '${continueVideoAudioInBackground.value}',
      );
      _applyBackgroundPolicy();
    });
  }

  // ---------------------------------------------------------------------------
  // Queue commands

  /// Replaces the queue and plays [media] from [startIndex]. Repeat and
  /// shuffle settings carry over.
  Future<void> playNow(List<MediaSource> media, {int startIndex = 0}) async {
    if (media.isEmpty) return;
    _savePosition();
    var next = PlayQueue.of(
      media.map(_newEntry).toList(),
      currentIndex: startIndex.clamp(0, media.length - 1),
      repeat: _queue.repeat,
    );
    if (_queue.shuffled) next = next.shuffle();
    _setQueue(next);
    await _loadCurrent(autoplay: true);
  }

  /// Restores the saved queue after process start without auto-playing
  /// (spec 7.1, 12: never resume playback unexpectedly after a restart).
  Future<void> restoreQueue() async {
    if (!_queue.isEmpty) return;
    final saved = await _queueStore.restore();
    if (saved == null || saved.isEmpty || !_queue.isEmpty) return;
    _setQueue(saved, persist: false);
    await _loadCurrent(autoplay: false);
    _log('queue restored (${saved.entries.length} items)');
  }

  /// Removes a queued item other than the current one (spec 7.1).
  void removeQueueEntry(int index) => _setQueue(_queue.removeAt(index));

  /// Reorders the queue; the current item keeps playing.
  void moveQueueEntry(int from, int to) => _setQueue(_queue.move(from, to));

  void clearUpcoming() => _setQueue(_queue.clearUpcoming());

  void setRepeat(QueueRepeat mode) {
    _setQueue(_queue.withRepeat(mode));
    _broadcast(force: true);
  }

  void setShuffle(bool enabled) {
    if (enabled == _queue.shuffled) return;
    _setQueue(enabled ? _queue.shuffle() : _queue.unshuffle());
    _broadcast(force: true);
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed.value = speed;
    await controller.value?.setPlaybackSpeed(speed);
    _broadcast(force: true);
  }

  /// Pauses after [after], or at the end of the current item when
  /// [endOfItem] is set; null cancels (spec 6.3).
  void setSleepTimer({Duration? after, bool endOfItem = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (endOfItem) {
      sleepTimer.value = const SleepTimer.endOfItem();
    } else if (after != null) {
      sleepTimer.value = SleepTimer.after(DateTime.now().add(after));
      _sleepTimer = Timer(after, () {
        _log('sleep timer -> pause');
        sleepTimer.value = null;
        pause();
      });
    } else {
      sleepTimer.value = null;
    }
  }

  /// Loads external subtitles for the current item (null removes them).
  Future<void> setSubtitles(SubtitleTrack? track) async {
    final media = _queue.current?.media;
    if (media == null) return;
    if (track == null) {
      _subtitlesByMedia.remove(media.id);
    } else {
      _subtitlesByMedia[media.id] = track;
    }
    subtitles.value = track;
    await controller.value?.setClosedCaptionFile(
      track == null ? null : Future.value(track.captions),
    );
  }

  /// Positive delays show subtitles later, negative earlier.
  void setSubtitleOffset(Duration offset) {
    subtitleOffset.value = offset;
    controller.value?.setCaptionOffset(offset);
  }

  /// Embedded audio tracks of the current item; empty when the engine
  /// cannot list them.
  Future<List<VideoAudioTrack>> audioTracks() async {
    final c = controller.value;
    if (c == null || !c.isAudioTrackSupportAvailable()) return const [];
    return c.getAudioTracks();
  }

  Future<void> selectAudioTrack(String id) async =>
      controller.value?.selectAudioTrack(id);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async =>
      setRepeat(switch (repeatMode) {
        AudioServiceRepeatMode.none => QueueRepeat.off,
        AudioServiceRepeatMode.one => QueueRepeat.one,
        AudioServiceRepeatMode.all ||
        AudioServiceRepeatMode.group => QueueRepeat.all,
      });

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async =>
      setShuffle(shuffleMode != AudioServiceShuffleMode.none);

  @override
  Future<void> removeQueueItemAt(int index) async => removeQueueEntry(index);

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
    if (c == null) {
      // E.g. a headset Play after the queue was restored but not loaded.
      if (!_queue.isEmpty && _loadGeneration == 0) {
        await _loadCurrent(autoplay: true);
      }
      return;
    }
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
      _onLoadError?.call(media);
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
    unawaited(_loadArtwork(entry, generation, c.value.duration));
    final saved = await _progressStore.resumePosition(media.id);
    if (generation != _loadGeneration) {
      await c.dispose();
      return;
    }
    if (saved != null &&
        saved > Duration.zero &&
        saved < c.value.duration - kSeekStep) {
      await c.seekTo(saved);
    }
    // Change detection must start fresh for the new engine; otherwise a
    // "playing" carried over from the previous item suppresses the broadcast
    // and the system session stays in "loading" (found on device, 2026-10-26).
    _lastPlaying = null;
    _lastBuffering = null;
    c.addListener(_onControllerChanged);
    controller.value = c;
    _log('loaded ${media.kind.name} "${media.title}"');
    if (speed.value != 1.0) await c.setPlaybackSpeed(speed.value);
    final track = _subtitlesByMedia[media.id];
    subtitles.value = track;
    if (track != null) {
      await c.setClosedCaptionFile(Future.value(track.captions));
      c.setCaptionOffset(subtitleOffset.value);
    }
    if (autoplay) await c.play();
    _broadcast(force: true);
  }

  Future<void> _disposeController() async {
    _progressTimer?.cancel();
    _progressTimer = null;
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
      _updateProgressTimer(v.isPlaying);
    }
  }

  Future<void> _onCompleted() async {
    _savePosition(completed: true);
    if (sleepTimer.value?.endOfItem ?? false) {
      sleepTimer.value = null;
      _broadcast(force: true, completed: true);
      _log('sleep timer: stopped at end of item');
      return;
    }
    switch (_queue.onCompletion) {
      case CompletionAction.restartCurrent:
        final c = controller.value;
        if (c == null) return;
        _completionHandled = false;
        await c.seekTo(Duration.zero);
        await c.play();
      case CompletionAction.advance:
        _setQueue(_queue.next());
        await _loadCurrent(autoplay: _autoplayAllowed());
      case CompletionAction.stop:
        // Retain a useful completed state rather than clearing the queue.
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
        repeatMode: switch (_queue.repeat) {
          QueueRepeat.off => AudioServiceRepeatMode.none,
          QueueRepeat.one => AudioServiceRepeatMode.one,
          QueueRepeat.all => AudioServiceRepeatMode.all,
        },
        shuffleMode: _queue.shuffled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  Future<void> _seekBy(Duration delta) async {
    final c = controller.value;
    if (c == null) return;
    await seek(seekBy(c.value.position, delta, c.value.duration));
  }

  void _updateProgressTimer(bool playing) {
    if (!playing) {
      _progressTimer?.cancel();
      _progressTimer = null;
    } else {
      _progressTimer ??= Timer.periodic(
        PlaybackProgressStore.periodicSaveInterval,
        (_) => _savePosition(),
      );
    }
  }

  void _savePosition({bool completed = false}) {
    final entry = _queue.current;
    final c = controller.value;
    if (entry == null || c == null || !c.value.isInitialized) return;
    unawaited(
      _progressStore
          .save(entry.media.id, c.value.position, completed: completed)
          .catchError((Object e) => _log('progress save failed: $e')),
    );
  }

  void _setQueue(PlayQueue next, {bool persist = true}) {
    playQueue.value = next;
    queue.add(next.entries.map(_toMediaItem).toList());
    if (!persist) return;
    // Debounced so bursts of edits (drag reorder) write once.
    _queueSaveTimer?.cancel();
    _queueSaveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(
        _queueStore
            .save(playQueue.value)
            .catchError((Object e) => _log('queue save failed: $e')),
      );
    });
  }

  // Unique across process restarts so restored entries never collide.
  QueueEntry _newEntry(MediaSource media) => QueueEntry(
    entryId: 'q${DateTime.now().microsecondsSinceEpoch}_${_entryCounter++}',
    media: media,
  );

  Future<void> _loadArtwork(
    QueueEntry entry,
    int generation,
    Duration duration,
  ) async {
    final loader = _artwork;
    if (loader == null) return;
    final id = entry.media.id;
    final Uri? uri;
    if (_artworkCache.containsKey(id)) {
      uri = _artworkCache[id];
    } else {
      try {
        uri = _artworkCache[id] = await loader(entry.media);
      } on Exception {
        return;
      }
    }
    if (uri == null || generation != _loadGeneration) return;
    mediaItem.add(_toMediaItem(entry, duration: duration, artUri: uri));
  }

  MediaItem _toMediaItem(QueueEntry entry, {Duration? duration, Uri? artUri}) =>
      MediaItem(
        id: entry.entryId,
        title: entry.media.title,
        // Tag metadata only; never fabricated (spec 6.1).
        album: entry.media.album,
        artist: entry.media.artist,
        duration: duration,
        artUri: artUri,
        extras: {'kind': entry.media.kind.name, 'mediaId': entry.media.id},
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
