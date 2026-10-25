import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../shared/data/app_database.dart';
import '../application/queue_store.dart';
import '../domain/media_source.dart';
import '../domain/play_queue.dart';

/// Saves the queue order, current entry, repeat mode and pre-shuffle order.
/// Entries for media outside the library (e.g. debug paths) are not saved.
class DriftQueueStore implements QueueStore {
  DriftQueueStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(PlayQueue queue) => _db.transaction(() async {
    final known = queue.entries.isEmpty
        ? <String>{}
        : {
            for (final row
                in await (_db.selectOnly(_db.mediaItems)
                      ..addColumns([_db.mediaItems.id])
                      ..where(
                        _db.mediaItems.id.isIn(
                          queue.entries.map((e) => e.media.id),
                        ),
                      ))
                    .get())
              row.read(_db.mediaItems.id)!,
          };
    await _db.delete(_db.queueEntries).go();
    await _db.batch((batch) {
      var order = 0;
      for (final e in queue.entries) {
        if (!known.contains(e.media.id)) continue;
        batch.insert(
          _db.queueEntries,
          QueueEntriesCompanion.insert(
            entryId: e.entryId,
            mediaId: e.media.id,
            orderIndex: order++,
          ),
        );
      }
    });
    await _db
        .into(_db.queueState)
        .insertOnConflictUpdate(
          QueueStateCompanion.insert(
            id: const Value(0),
            currentEntryId: Value(queue.current?.entryId),
            repeatMode: Value(queue.repeat.name),
            unshuffledJson: Value(
              queue.unshuffled == null ? null : jsonEncode(queue.unshuffled),
            ),
            updatedAt: DateTime.now(),
          ),
        );
  });

  @override
  Future<PlayQueue?> restore() async {
    final state = await (_db.select(
      _db.queueState,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    final rows =
        await (_db.select(_db.queueEntries).join([
                innerJoin(
                  _db.mediaItems,
                  _db.mediaItems.id.equalsExp(_db.queueEntries.mediaId),
                ),
              ])
              ..where(_db.mediaItems.available.equals(true))
              ..orderBy([OrderingTerm.asc(_db.queueEntries.orderIndex)]))
            .get();
    final repeat =
        QueueRepeat.values.asNameMap()[state?.repeatMode] ?? QueueRepeat.off;
    if (rows.isEmpty) return null;
    final entries = [
      for (final r in rows)
        QueueEntry(
          entryId: r.readTable(_db.queueEntries).entryId,
          media: _source(r.readTable(_db.mediaItems)),
        ),
    ];
    final current = entries.indexWhere(
      (e) => e.entryId == state?.currentEntryId,
    );
    final unshuffled = state?.unshuffledJson == null
        ? null
        : (jsonDecode(state!.unshuffledJson!) as List).cast<String>();
    return PlayQueue.of(
      entries,
      currentIndex: current < 0 ? 0 : current,
      repeat: repeat,
      unshuffled: unshuffled,
    );
  }

  static MediaSource _source(LibraryItem item) => MediaSource(
    id: item.id,
    title: item.title,
    locator: item.locator,
    kind: item.kind,
    artist: item.artist,
    album: item.album,
  );
}
