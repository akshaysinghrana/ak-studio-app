import 'package:drift/drift.dart';

import '../../../shared/data/app_database.dart';
import '../application/playback_progress_store.dart';

/// Stores resume positions in `playback_progress` as integer milliseconds.
/// Items not in the library (e.g. debug autoload paths) are ignored.
class DriftPlaybackProgressStore implements PlaybackProgressStore {
  DriftPlaybackProgressStore(this._db);

  final AppDatabase _db;

  @override
  Future<Duration?> resumePosition(String mediaId) async {
    final row = await (_db.select(
      _db.playbackProgress,
    )..where((t) => t.mediaId.equals(mediaId))).getSingleOrNull();
    if (row == null || row.completed) return null;
    return Duration(milliseconds: row.positionMs);
  }

  @override
  Future<void> save(
    String mediaId,
    Duration position, {
    required bool completed,
  }) async {
    final known =
        await (_db.selectOnly(_db.mediaItems)
              ..addColumns([_db.mediaItems.id])
              ..where(_db.mediaItems.id.equals(mediaId)))
            .getSingleOrNull();
    if (known == null) return;
    final now = DateTime.now();
    await _db
        .into(_db.playbackProgress)
        .insertOnConflictUpdate(
          PlaybackProgressCompanion.insert(
            mediaId: mediaId,
            positionMs: position.inMilliseconds,
            completed: Value(completed),
            lastPlayedAt: now,
            updatedAt: now,
          ),
        );
  }
}
