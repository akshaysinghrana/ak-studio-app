import 'dart:math';

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

enum QueueRepeat { off, one, all }

/// What happens when the current item finishes.
enum CompletionAction { restartCurrent, advance, stop }

/// Immutable play queue in playback order. Edits to other entries never change
/// [current] (spec 7.1). With shuffle on, [entries] holds the shuffled order
/// and [unshuffled] remembers the original order so shuffle can be undone.
class PlayQueue {
  const PlayQueue._(
    this.entries,
    this.currentIndex, {
    this.repeat = QueueRepeat.off,
    this.unshuffled,
  });

  const PlayQueue.empty()
    : entries = const [],
      currentIndex = -1,
      repeat = QueueRepeat.off,
      unshuffled = null;

  factory PlayQueue.of(
    List<QueueEntry> entries, {
    int currentIndex = 0,
    QueueRepeat repeat = QueueRepeat.off,
    List<String>? unshuffled,
  }) {
    if (entries.isEmpty) return PlayQueue.empty().withRepeat(repeat);
    RangeError.checkValidIndex(currentIndex, entries, 'currentIndex');
    return PlayQueue._(
      List.unmodifiable(entries),
      currentIndex,
      repeat: repeat,
      unshuffled: unshuffled == null ? null : List.unmodifiable(unshuffled),
    );
  }

  final List<QueueEntry> entries;
  final int currentIndex;
  final QueueRepeat repeat;

  /// Entry IDs in their pre-shuffle order; null when shuffle is off.
  final List<String>? unshuffled;

  bool get isEmpty => entries.isEmpty;
  bool get shuffled => unshuffled != null;
  QueueEntry? get current => isEmpty ? null : entries[currentIndex];
  bool get hasNext =>
      currentIndex + 1 < entries.length ||
      (repeat == QueueRepeat.all && entries.isNotEmpty);
  bool get hasPrevious => currentIndex > 0;
  int get upcomingCount => isEmpty ? 0 : entries.length - currentIndex - 1;

  PlayQueue _copy(
    List<QueueEntry> entries,
    int currentIndex, {
    List<String>? unshuffled,
  }) => entries.isEmpty
      ? PlayQueue.empty().withRepeat(repeat)
      : PlayQueue._(
          List.unmodifiable(entries),
          currentIndex,
          repeat: repeat,
          unshuffled: unshuffled == null ? null : List.unmodifiable(unshuffled),
        );

  PlayQueue withRepeat(QueueRepeat mode) =>
      PlayQueue._(entries, currentIndex, repeat: mode, unshuffled: unshuffled);

  // ---------------------------------------------------------------------------
  // Additions

  PlayQueue append(QueueEntry entry) => isEmpty
      ? PlayQueue.of([entry], repeat: repeat)
      : _copy([...entries, entry], currentIndex, unshuffled: _withNew(entry));

  /// Inserts directly after the current item without clearing anything.
  PlayQueue playNext(QueueEntry entry) {
    if (isEmpty) return PlayQueue.of([entry], repeat: repeat);
    final list = [...entries]..insert(currentIndex + 1, entry);
    return _copy(
      list,
      currentIndex,
      unshuffled: _withNew(entry, afterCurrent: true),
    );
  }

  List<String>? _withNew(QueueEntry entry, {bool afterCurrent = false}) {
    final order = unshuffled;
    if (order == null) return null;
    final list = [...order];
    final at = afterCurrent ? list.indexOf(current!.entryId) + 1 : list.length;
    list.insert(at, entry.entryId);
    return list;
  }

  // ---------------------------------------------------------------------------
  // Edits that never touch the current item

  /// Removes a non-current entry. Returns this queue unchanged for the current
  /// item; skipping away from it is a separate, explicit action.
  PlayQueue removeAt(int index) {
    if (index < 0 || index >= entries.length || index == currentIndex) {
      return this;
    }
    final removed = entries[index];
    final list = [...entries]..removeAt(index);
    return _copy(
      list,
      index < currentIndex ? currentIndex - 1 : currentIndex,
      unshuffled: unshuffled?.where((id) => id != removed.entryId).toList(),
    );
  }

  /// Moves an entry; the current item stays current wherever it ends up.
  PlayQueue move(int from, int to) {
    if (from < 0 || from >= entries.length) return this;
    final target = to.clamp(0, entries.length - 1);
    if (from == target) return this;
    final currentId = current!.entryId;
    final list = [...entries];
    list.insert(target, list.removeAt(from));
    return _copy(
      list,
      list.indexWhere((e) => e.entryId == currentId),
      unshuffled: unshuffled,
    );
  }

  /// Keeps already-played entries and the current one.
  PlayQueue clearUpcoming() {
    if (isEmpty) return this;
    final kept = entries.sublist(0, currentIndex + 1);
    final keptIds = {for (final e in kept) e.entryId};
    return _copy(
      kept,
      currentIndex,
      unshuffled: unshuffled?.where(keptIds.contains).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation

  PlayQueue jumpTo(int index) => _copy(
    entries,
    RangeError.checkValidIndex(index, entries),
    unshuffled: unshuffled,
  );

  /// Next entry; wraps to the start only with repeat-all.
  PlayQueue next() {
    if (isEmpty) return this;
    if (currentIndex + 1 < entries.length) return jumpTo(currentIndex + 1);
    return repeat == QueueRepeat.all ? jumpTo(0) : this;
  }

  PlayQueue previous() => hasPrevious ? jumpTo(currentIndex - 1) : this;

  /// Spec 7.1: past the threshold restart the current item, otherwise go back
  /// when a previous item exists.
  PreviousAction previousAction(Duration position) =>
      position > kPreviousRestartThreshold || !hasPrevious
      ? PreviousAction.restartCurrent
      : PreviousAction.goToPrevious;

  CompletionAction get onCompletion {
    if (isEmpty) return CompletionAction.stop;
    if (repeat == QueueRepeat.one) return CompletionAction.restartCurrent;
    if (currentIndex + 1 < entries.length || repeat == QueueRepeat.all) {
      return CompletionAction.advance;
    }
    return CompletionAction.stop;
  }

  // ---------------------------------------------------------------------------
  // Shuffle

  /// Current item first, then every other entry in random order, so nothing
  /// repeats before the whole set has played (spec 7.1).
  PlayQueue shuffle([Random? random]) {
    if (isEmpty) return this;
    final original = unshuffled ?? [for (final e in entries) e.entryId];
    final rest = [...entries]..removeAt(currentIndex);
    rest.shuffle(random ?? Random());
    return _copy([current!, ...rest], 0, unshuffled: original);
  }

  /// Restores the pre-shuffle order (entries added meanwhile keep their
  /// relative position) with the same current item.
  PlayQueue unshuffle() {
    final order = unshuffled;
    if (order == null || isEmpty) return _copy(entries, currentIndex);
    final byId = {for (final e in entries) e.entryId: e};
    final list = [
      for (final id in order)
        if (byId.containsKey(id)) byId[id]!,
    ];
    final known = order.toSet();
    list.addAll(entries.where((e) => !known.contains(e.entryId)));
    final currentId = current!.entryId;
    return _copy(list, list.indexWhere((e) => e.entryId == currentId));
  }
}
