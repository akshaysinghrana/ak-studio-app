import 'media_source.dart';
import 'seek.dart';

/// One slot in the queue. Entries have their own IDs so the same media can be
/// queued more than once (spec 7.1, 11).
class QueueEntry {
  const QueueEntry({required this.entryId, required this.media});

  final String entryId;
  final MediaSource media;
}

enum PreviousAction { restartCurrent, goToPrevious }

/// Immutable play queue. Edits to upcoming entries never change [current].
class PlayQueue {
  const PlayQueue._(this.entries, this.currentIndex);

  const PlayQueue.empty() : entries = const [], currentIndex = -1;

  factory PlayQueue.of(List<QueueEntry> entries, {int currentIndex = 0}) {
    if (entries.isEmpty) return const PlayQueue.empty();
    RangeError.checkValidIndex(currentIndex, entries, 'currentIndex');
    return PlayQueue._(List.unmodifiable(entries), currentIndex);
  }

  final List<QueueEntry> entries;
  final int currentIndex;

  bool get isEmpty => entries.isEmpty;
  QueueEntry? get current => isEmpty ? null : entries[currentIndex];
  bool get hasNext => currentIndex + 1 < entries.length;
  bool get hasPrevious => currentIndex > 0;

  PlayQueue append(QueueEntry entry) => isEmpty
      ? PlayQueue.of([entry])
      : PlayQueue._(List.unmodifiable([...entries, entry]), currentIndex);

  /// Inserts directly after the current item without clearing anything.
  PlayQueue playNext(QueueEntry entry) {
    if (isEmpty) return PlayQueue.of([entry]);
    final list = [...entries]..insert(currentIndex + 1, entry);
    return PlayQueue._(List.unmodifiable(list), currentIndex);
  }

  PlayQueue jumpTo(int index) => PlayQueue.of(entries, currentIndex: index);

  PlayQueue next() => hasNext ? jumpTo(currentIndex + 1) : this;

  PlayQueue previous() => hasPrevious ? jumpTo(currentIndex - 1) : this;

  /// Spec 7.1: past the threshold restart the current item, otherwise go back
  /// when a previous item exists.
  PreviousAction previousAction(Duration position) =>
      position > kPreviousRestartThreshold || !hasPrevious
      ? PreviousAction.restartCurrent
      : PreviousAction.goToPrevious;
}
