import 'dart:math';

import 'package:drift/drift.dart';

import '../../../shared/data/app_database.dart';
import '../../library/data/media_library_repository.dart';
import '../../sync/application/sync_service.dart';
import '../../sync/domain/media_fingerprint.dart';

class PlaylistSummary {
  const PlaylistSummary(this.playlist, this.count, this.totalDurationMs);

  final PlaylistRow playlist;
  final int count;
  final int totalDurationMs;
}

/// A playlist row with its library item (which may be unavailable).
class PlaylistItem {
  const PlaylistItem(this.entryId, this.media);

  final String entryId;
  final LibraryEntry media;
}

class AddResult {
  const AddResult({required this.added, required this.duplicates});

  final int added;

  /// Items already in the playlist and therefore not added again.
  final int duplicates;
}

/// Local playlists and favourites (spec 7.2). Works for guests and offline.
/// Duplicates are rejected by default; callers ask the user before adding a
/// duplicate with `allowDuplicates: true`.
class PlaylistRepository {
  PlaylistRepository(this._db, {Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final Random _random;

  $PlaylistsTable get _playlists => _db.playlists;
  $PlaylistEntriesTable get _entries => _db.playlistEntries;
  $MediaItemsTable get _items => _db.mediaItems;

  // ---------------------------------------------------------------------------
  // Playlists

  Stream<List<PlaylistSummary>> watchPlaylists() {
    final count = _entries.id.count();
    final total = _items.durationMs.sum();
    final query =
        _db.select(_playlists).join([
            leftOuterJoin(
              _entries,
              _entries.playlistId.equalsExp(_playlists.id),
            ),
            leftOuterJoin(_items, _items.id.equalsExp(_entries.mediaId)),
          ])
          ..addColumns([count, total])
          ..groupBy([_playlists.id])
          ..orderBy([
            OrderingTerm.asc(_playlists.sortOrder),
            OrderingTerm.asc(_playlists.name.collate(Collate.noCase)),
          ]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          PlaylistSummary(
            r.readTable(_playlists),
            r.read(count) ?? 0,
            r.read(total) ?? 0,
          ),
      ],
    );
  }

  Stream<PlaylistRow?> watchPlaylist(String id) => (_db.select(
    _playlists,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<List<PlaylistItem>> watchItems(String playlistId) {
    final query =
        _db.select(_entries).join([
            innerJoin(_items, _items.id.equalsExp(_entries.mediaId)),
            leftOuterJoin(
              _db.playbackProgress,
              _db.playbackProgress.mediaId.equalsExp(_items.id),
            ),
          ])
          ..where(_entries.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(_entries.orderIndex)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          PlaylistItem(
            r.readTable(_entries).id,
            LibraryEntry(
              r.readTable(_items),
              r.readTableOrNull(_db.playbackProgress),
            ),
          ),
      ],
    );
  }

  Future<String> create(String name) async {
    final id = _newId('p');
    final now = DateTime.now();
    await _db
        .into(_playlists)
        .insert(
          PlaylistsCompanion.insert(
            id: id,
            name: _cleanName(name),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> rename(String id, String name) =>
      (_db.update(_playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(
          name: Value(_cleanName(name)),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes the playlist and its entries; media files are untouched. A
  /// playlist attached to an account leaves a tombstone so the deletion syncs.
  Future<void> delete(String id) => _db.transaction(() async {
    final row = await (_db.select(
      _playlists,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    await (_db.delete(_playlists)..where((t) => t.id.equals(id))).go();
    final owner = row?.userId;
    if (owner != null) await _tombstone('playlist', id, owner);
  });

  Future<void> _tombstone(String kind, String recordId, String userId) => _db
      .into(_db.syncTombstones)
      .insertOnConflictUpdate(
        SyncTombstonesCompanion.insert(
          kind: kind,
          recordId: recordId,
          userId: userId,
          deletedAt: DateTime.now(),
        ),
      );

  Future<AddResult> addMedia(
    String playlistId,
    List<String> mediaIds, {
    bool allowDuplicates = false,
  }) => _db.transaction(() async {
    final existing = {
      for (final e in await (_db.select(
        _entries,
      )..where((t) => t.playlistId.equals(playlistId))).get())
        e.mediaId,
    };
    var order = existing.length;
    var added = 0, duplicates = 0;
    final seen = <String>{};
    final now = DateTime.now();
    await _db.batch((batch) {
      for (final mediaId in mediaIds) {
        final duplicate = existing.contains(mediaId) || seen.contains(mediaId);
        if (duplicate && !allowDuplicates) {
          duplicates++;
          continue;
        }
        seen.add(mediaId);
        batch.insert(
          _entries,
          PlaylistEntriesCompanion.insert(
            id: _newId('e'),
            playlistId: playlistId,
            mediaId: mediaId,
            orderIndex: order++,
            addedAt: now,
          ),
        );
        added++;
      }
    });
    await _touch(playlistId);
    return AddResult(added: added, duplicates: duplicates);
  });

  Future<bool> contains(String playlistId, String mediaId) async =>
      await (_db.select(_entries)
            ..where(
              (t) =>
                  t.playlistId.equals(playlistId) & t.mediaId.equals(mediaId),
            )
            ..limit(1))
          .getSingleOrNull() !=
      null;

  Future<void> removeEntry(String playlistId, String entryId) =>
      _db.transaction(() async {
        await (_db.delete(_entries)..where((t) => t.id.equals(entryId))).go();
        await _reindex(playlistId, null);
      });

  Future<void> moveEntry(String playlistId, int from, int to) =>
      _db.transaction(() => _reindex(playlistId, (from, to)));

  /// Saves the given queue order as a new playlist (duplicates skipped).
  Future<(String, AddResult)> saveAsPlaylist(
    String name,
    List<String> mediaIds,
  ) async {
    final id = await create(name);
    return (id, await addMedia(id, mediaIds));
  }

  Future<void> _reindex(String playlistId, (int, int)? move) async {
    final rows =
        await (_db.select(_entries)
              ..where((t) => t.playlistId.equals(playlistId))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
            .get();
    if (move != null) {
      final (from, to) = move;
      if (from < 0 || from >= rows.length) return;
      rows.insert(to.clamp(0, rows.length - 1), rows.removeAt(from));
    }
    await _db.batch((batch) {
      for (final (i, row) in rows.indexed) {
        if (row.orderIndex != i) {
          batch.update(
            _entries,
            PlaylistEntriesCompanion(orderIndex: Value(i)),
            where: (t) => t.id.equals(row.id),
          );
        }
      }
    });
    await _touch(playlistId);
  }

  Future<void> _touch(String id) =>
      (_db.update(_playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(updatedAt: Value(DateTime.now())),
      );

  // ---------------------------------------------------------------------------
  // Favourites (built-in collection)

  Stream<bool> watchIsFavorite(String mediaId) =>
      (_db.select(_db.favorites)..where((t) => t.mediaId.equals(mediaId)))
          .watchSingleOrNull()
          .map((row) => row != null);

  /// Returns the new favourite state.
  Future<bool> toggleFavorite(String mediaId) => _db.transaction(() async {
    final removed = await (_db.delete(
      _db.favorites,
    )..where((t) => t.mediaId.equals(mediaId))).go();
    if (removed > 0) {
      final syncUser = await _syncUserId();
      final item = await (_db.select(
        _items,
      )..where((t) => t.id.equals(mediaId))).getSingleOrNull();
      if (syncUser != null && item != null) {
        await _tombstone('favorite', mediaFingerprint(item), syncUser);
      }
      return false;
    }
    await _db
        .into(_db.favorites)
        .insert(
          FavoritesCompanion.insert(
            mediaId: mediaId,
            createdAt: DateTime.now(),
          ),
        );
    return true;
  });

  Stream<List<LibraryEntry>> watchFavorites() {
    final query = _db.select(_db.favorites).join([
      innerJoin(_items, _items.id.equalsExp(_db.favorites.mediaId)),
      leftOuterJoin(
        _db.playbackProgress,
        _db.playbackProgress.mediaId.equalsExp(_items.id),
      ),
    ])..orderBy([OrderingTerm.desc(_db.favorites.createdAt)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          LibraryEntry(
            r.readTable(_items),
            r.readTableOrNull(_db.playbackProgress),
          ),
      ],
    );
  }

  Future<String?> _syncUserId() async =>
      (await (_db.select(_db.userPreferences)
                ..where((t) => t.key.equals(SyncService.syncUserKey)))
              .getSingleOrNull())
          ?.value;

  static String _cleanName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Untitled playlist' : trimmed;
  }

  String _newId(String prefix) {
    final bytes = List<int>.generate(12, (_) => _random.nextInt(256));
    return '${prefix}_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }
}
