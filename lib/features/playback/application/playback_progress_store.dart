/// Persists resume positions for the coordinator (spec 4.2). Writes are
/// throttled by the caller: on pause, background, item change, completion and
/// every [PlaybackProgressStore.periodicSaveInterval] while playing.
abstract interface class PlaybackProgressStore {
  static const periodicSaveInterval = Duration(seconds: 10);

  /// Saved position to resume from, or null when there is none or the item
  /// was completed.
  Future<Duration?> resumePosition(String mediaId);

  Future<void> save(
    String mediaId,
    Duration position, {
    required bool completed,
  });
}

class InMemoryPlaybackProgressStore implements PlaybackProgressStore {
  final Map<String, (Duration, bool)> _positions = {};

  @override
  Future<Duration?> resumePosition(String mediaId) async {
    final saved = _positions[mediaId];
    return saved == null || saved.$2 ? null : saved.$1;
  }

  @override
  Future<void> save(
    String mediaId,
    Duration position, {
    required bool completed,
  }) async {
    _positions[mediaId] = (position, completed);
  }
}
