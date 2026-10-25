import 'dart:math';

import 'package:drift/drift.dart';

import '../../../shared/data/app_database.dart';
import '../data/remote_store.dart';
import '../domain/media_fingerprint.dart';

class SyncResult {
  const SyncResult({required this.pulled, required this.pushed});

  final int pulled;
  final int pushed;
}

/// Metadata sync for a signed-in user (spec 9.2, ADR 0003).
///
/// What syncs: playlists the user attached to the account, favourites and
/// sync-eligible preferences. Media is referenced only by [mediaFingerprint];
/// files, names, paths and history are never uploaded.
///
/// Conflicts: last write wins per record, by millisecond `updatedAt`. A local
/// change is never overwritten by an older remote copy. Deletions travel as
/// tombstones. Playlist entries for files missing on this device are kept in
/// the remote copy rather than dropped.
class SyncService {
  SyncService(this._db, this._remote, {Random? random})
    : _random = random ?? Random.secure();

  final AppDatabase _db;
  final RemoteStore _remote;
  final Random _random;

  /// Preference holding the account this device syncs with; never synced.
  static const syncUserKey = 'sync.userId';

  // ---------------------------------------------------------------------------
  // Enable / disable

  Future<String?> syncUserId() async => (await (_db.select(
    _db.userPreferences,
  )..where((t) => t.key.equals(syncUserKey))).getSingleOrNull())?.value;

  /// Local playlists not attached to any account (for the consent prompt).
  Future<int> unattachedPlaylistCount() async {
    final count = _db.playlists.id.count();
    final row =
        await (_db.selectOnly(_db.playlists)
              ..addColumns([count])
              ..where(_db.playlists.userId.isNull()))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Turns sync on for [uid]. Guest playlists are attached only when the user
  /// agreed ([attachLocalPlaylists]), so local data never leaks silently.
  Future<void> enable(
    String uid, {
    required bool attachLocalPlaylists,
  }) => _db.transaction(() async {
    await _db
        .into(_db.userPreferences)
        .insertOnConflictUpdate(
          UserPreferencesCompanion.insert(
            key: syncUserKey,
            value: uid,
            updatedAt: DateTime.now(),
          ),
        );
    if (attachLocalPlaylists) {
      await (_db.update(_db.playlists)..where((t) => t.userId.isNull())).write(
        PlaylistsCompanion(ownerScope: const Value('user'), userId: Value(uid)),
      );
    }
  });

  /// Turns sync off. Local data stays unless [removeAccountData] is set
  /// (the UI asks first, spec 9.2).
  Future<void> disable(String uid, {bool removeAccountData = false}) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.userPreferences,
        )..where((t) => t.key.equals(syncUserKey))).go();
        if (removeAccountData) {
          await (_db.delete(
            _db.playlists,
          )..where((t) => t.userId.equals(uid))).go();
          await (_db.delete(
            _db.syncTombstones,
          )..where((t) => t.userId.equals(uid))).go();
          await (_db.delete(
            _db.syncMetadata,
          )..where((t) => t.userId.equals(uid))).go();
        }
      });

  Stream<SyncMetadataRow?> watchMetadata(String uid) => (_db.select(
    _db.syncMetadata,
  )..where((t) => t.userId.equals(uid))).watchSingleOrNull();

  // ---------------------------------------------------------------------------
  // Sync

  Future<SyncResult> sync(String uid) async {
    try {
      final index = await _fingerprintIndex();
      var pulled = 0, pushed = 0;
      final p = await _syncPlaylists(uid, index);
      final f = await _syncFavorites(uid, index);
      final s = await _syncSettings(uid);
      pulled = p.pulled + f.pulled + s.pulled;
      pushed = p.pushed + f.pushed + s.pushed;
      await _db
          .into(_db.syncMetadata)
          .insertOnConflictUpdate(
            SyncMetadataCompanion.insert(
              userId: uid,
              lastSyncAt: Value(DateTime.now()),
              lastError: const Value(null),
            ),
          );
      return SyncResult(pulled: pulled, pushed: pushed);
    } catch (e) {
      await _db
          .into(_db.syncMetadata)
          .insertOnConflictUpdate(
            SyncMetadataCompanion(userId: Value(uid), lastError: Value('$e')),
          );
      rethrow;
    }
  }

  Future<_Index> _fingerprintIndex() async {
    final items = await _db.select(_db.mediaItems).get();
    final byFp = <String, String>{};
    final byId = <String, String>{};
    for (final item in items) {
      final fp = mediaFingerprint(item);
      byFp.putIfAbsent(fp, () => item.id);
      byId[item.id] = fp;
    }
    return _Index(byFp, byId);
  }

  Future<SyncResult> _syncPlaylists(String uid, _Index index) async {
    final remote = await _remote.list(uid, 'playlists');
    final local = {
      for (final p in await (_db.select(
        _db.playlists,
      )..where((t) => t.userId.equals(uid))).get())
        p.id: p,
    };
    final tombs = await _tombstones(uid, 'playlist');
    final toPush = <String, Map<String, Object?>>{};
    var pulled = 0;

    for (final MapEntry(key: id, value: doc) in remote.entries) {
      final remoteAt = _ms(doc['updatedAt']);
      final remoteFps = (doc['entries'] as List? ?? const []).cast<String>();
      final p = local.remove(id);
      final tomb = tombs.remove(id);

      if (doc['deleted'] == true) {
        if (p == null) continue;
        if (_at(p.updatedAt) > remoteAt) {
          toPush[id] = await _playlistDoc(p, index, remoteFps);
        } else {
          await (_db.delete(_db.playlists)..where((t) => t.id.equals(id))).go();
          pulled++;
        }
        continue;
      }
      if (tomb != null && _at(tomb.deletedAt) >= remoteAt) {
        toPush[id] = _deletedDoc(tomb.deletedAt);
        continue;
      }
      if (p == null || remoteAt > _at(p.updatedAt)) {
        await _applyRemotePlaylist(uid, id, doc, remoteFps, index);
        pulled++;
      } else if (_at(p.updatedAt) > remoteAt) {
        toPush[id] = await _playlistDoc(p, index, remoteFps);
      }
    }
    for (final p in local.values) {
      toPush[p.id] = await _playlistDoc(p, index, const []);
    }
    for (final t in tombs.values) {
      toPush[t.recordId] = _deletedDoc(t.deletedAt);
    }
    if (toPush.isNotEmpty) await _remote.putAll(uid, 'playlists', toPush);
    await _clearTombstones(uid, 'playlist');
    return SyncResult(pulled: pulled, pushed: toPush.length);
  }

  Future<void> _applyRemotePlaylist(
    String uid,
    String id,
    Map<String, Object?> doc,
    List<String> fps,
    _Index index,
  ) => _db.transaction(() async {
    final at = DateTime.fromMillisecondsSinceEpoch(_ms(doc['updatedAt']));
    await _db
        .into(_db.playlists)
        .insertOnConflictUpdate(
          PlaylistsCompanion.insert(
            id: id,
            name: '${doc['name'] ?? 'Playlist'}',
            ownerScope: const Value('user'),
            userId: Value(uid),
            createdAt: at,
            updatedAt: at,
          ),
        );
    await (_db.delete(
      _db.playlistEntries,
    )..where((t) => t.playlistId.equals(id))).go();
    var order = 0;
    for (final fp in fps) {
      final mediaId = index.byFp[fp];
      if (mediaId == null) continue; // not on this device; kept remotely
      await _db
          .into(_db.playlistEntries)
          .insert(
            PlaylistEntriesCompanion.insert(
              id: _newId(),
              playlistId: id,
              mediaId: mediaId,
              orderIndex: order++,
              addedAt: at,
            ),
          );
    }
  });

  Future<Map<String, Object?>> _playlistDoc(
    PlaylistRow p,
    _Index index,
    List<String> remoteFps,
  ) async {
    final entries =
        await (_db.select(_db.playlistEntries)
              ..where((t) => t.playlistId.equals(p.id))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
            .get();
    final localFps = [
      for (final e in entries)
        if (index.byId[e.mediaId] != null) index.byId[e.mediaId]!,
    ];
    // Entries this device cannot see stay in the account copy.
    final missingHere = remoteFps.where((fp) => !index.byFp.containsKey(fp));
    return {
      'name': p.name,
      'updatedAt': _at(p.updatedAt),
      'deleted': false,
      'entries': [...localFps, ...missingHere],
    };
  }

  Future<SyncResult> _syncFavorites(String uid, _Index index) async {
    final remote = await _remote.list(uid, 'favorites');
    final local = {
      for (final f in await _db.select(_db.favorites).get())
        if (index.byId[f.mediaId] != null) index.byId[f.mediaId]!: f,
    };
    final tombs = await _tombstones(uid, 'favorite');
    final toPush = <String, Map<String, Object?>>{};
    var pulled = 0;

    for (final MapEntry(key: fp, value: doc) in remote.entries) {
      final remoteAt = _ms(doc['updatedAt']);
      final favourite = doc['favorite'] == true;
      final mine = local.remove(fp);
      final tomb = tombs.remove(fp);
      final mediaId = index.byFp[fp];
      if (mediaId == null) continue; // file not on this device
      if (favourite && mine == null) {
        if (tomb != null && _at(tomb.deletedAt) > remoteAt) {
          toPush[fp] = {'favorite': false, 'updatedAt': _at(tomb.deletedAt)};
        } else {
          await _db
              .into(_db.favorites)
              .insertOnConflictUpdate(
                FavoritesCompanion.insert(
                  mediaId: mediaId,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(remoteAt),
                ),
              );
          pulled++;
        }
      } else if (!favourite && mine != null) {
        if (_at(mine.createdAt) > remoteAt) {
          toPush[fp] = {'favorite': true, 'updatedAt': _at(mine.createdAt)};
        } else {
          await (_db.delete(
            _db.favorites,
          )..where((t) => t.mediaId.equals(mediaId))).go();
          pulled++;
        }
      }
    }
    for (final MapEntry(key: fp, value: f) in local.entries) {
      toPush[fp] = {'favorite': true, 'updatedAt': _at(f.createdAt)};
    }
    for (final t in tombs.values) {
      toPush[t.recordId] = {'favorite': false, 'updatedAt': _at(t.deletedAt)};
    }
    if (toPush.isNotEmpty) await _remote.putAll(uid, 'favorites', toPush);
    await _clearTombstones(uid, 'favorite');
    return SyncResult(pulled: pulled, pushed: toPush.length);
  }

  Future<SyncResult> _syncSettings(String uid) async {
    final remote = await _remote.list(uid, 'settings');
    final local = {
      for (final p in await (_db.select(
        _db.userPreferences,
      )..where((t) => t.syncEligible.equals(true))).get())
        if (p.key != syncUserKey) p.key: p,
    };
    final toPush = <String, Map<String, Object?>>{};
    var pulled = 0;
    for (final MapEntry(key: key, value: doc) in remote.entries) {
      final remoteAt = _ms(doc['updatedAt']);
      final mine = local.remove(key);
      if (mine == null || remoteAt > _at(mine.updatedAt)) {
        await _db
            .into(_db.userPreferences)
            .insertOnConflictUpdate(
              UserPreferencesCompanion.insert(
                key: key,
                value: '${doc['value']}',
                updatedAt: DateTime.fromMillisecondsSinceEpoch(remoteAt),
                syncEligible: const Value(true),
              ),
            );
        pulled++;
      } else if (_at(mine.updatedAt) > remoteAt) {
        toPush[key] = {'value': mine.value, 'updatedAt': _at(mine.updatedAt)};
      }
    }
    for (final p in local.values) {
      toPush[p.key] = {'value': p.value, 'updatedAt': _at(p.updatedAt)};
    }
    if (toPush.isNotEmpty) await _remote.putAll(uid, 'settings', toPush);
    return SyncResult(pulled: pulled, pushed: toPush.length);
  }

  // ---------------------------------------------------------------------------

  Future<Map<String, SyncTombstoneRow>> _tombstones(
    String uid,
    String kind,
  ) async => {
    for (final t in await (_db.select(
      _db.syncTombstones,
    )..where((t) => t.userId.equals(uid) & t.kind.equals(kind))).get())
      t.recordId: t,
  };

  Future<void> _clearTombstones(String uid, String kind) => (_db.delete(
    _db.syncTombstones,
  )..where((t) => t.userId.equals(uid) & t.kind.equals(kind))).go();

  static Map<String, Object?> _deletedDoc(DateTime at) => {
    'deleted': true,
    'updatedAt': _at(at),
    'entries': const <String>[],
  };

  static int _at(DateTime d) => d.millisecondsSinceEpoch;

  static int _ms(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

  String _newId() {
    final bytes = List<int>.generate(12, (_) => _random.nextInt(256));
    return 'e_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }
}

class _Index {
  const _Index(this.byFp, this.byId);

  /// Fingerprint → local media ID.
  final Map<String, String> byFp;

  /// Local media ID → fingerprint.
  final Map<String, String> byId;
}
