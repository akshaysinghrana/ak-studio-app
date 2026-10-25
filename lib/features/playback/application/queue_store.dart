import '../domain/play_queue.dart';

/// Persists the Now Playing queue so it survives process death (spec 7.1).
abstract interface class QueueStore {
  Future<void> save(PlayQueue queue);

  /// The last saved queue, or null. Items no longer playable are dropped.
  Future<PlayQueue?> restore();
}

class InMemoryQueueStore implements QueueStore {
  PlayQueue? _saved;

  @override
  Future<void> save(PlayQueue queue) async => _saved = queue;

  @override
  Future<PlayQueue?> restore() async => _saved;
}
