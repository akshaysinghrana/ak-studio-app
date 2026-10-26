import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/platform/media_store.dart';
import '../../../shared/data/app_database.dart';
import '../../playback/domain/media_source.dart';
import '../domain/media_record.dart';

enum LibrarySort { title, dateAdded, dateModified, duration, size, lastPlayed }

/// A library item with its playback progress, if any.
class LibraryEntry {
  const LibraryEntry(this.item, this.progress);

  final LibraryItem item;
  final PlaybackProgressRow? progress;

  MediaSource toMediaSource() => MediaSource(
    id: item.id,
    title: item.title,
    locator: item.locator,
    kind: item.kind,
    artist: item.artist,
    album: item.album,
  );
}

/// A folder of indexed media (MediaStore relative path, or null for files
/// imported through the picker).
class FolderSummary {
  const FolderSummary({
    required this.folder,
    required this.count,
    required this.totalBytes,
    required this.hidden,
    this.sampleLocator,
  });

  final String? folder;
  final int count;
  final int totalBytes;
  final bool hidden;

  /// Any item in the folder, for a thumbnail.
  final String? sampleLocator;

  /// Last path segment, e.g. `Camera` for `DCIM/Camera/`.
  String get name {
    final f = folder;
    if (f == null || f.isEmpty) return 'Other files';
    final parts = f.split('/').where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? f : parts.last;
  }

  /// Full relative path, shown under the name.
  String get path => folder ?? 'Imported with Choose files';
}

class ScanSummary {
  const ScanSummary({
    required this.added,
    required this.updated,
    required this.missing,
    required this.restored,
  });

  final int added;
  final int updated;
  final int missing;
  final int restored;
}

class ImportSummary {
  const ImportSummary({required this.imported, required this.skipped});

  final List<LibraryEntry> imported;

  /// Picked files that are not MP4/MP3 or could not be read.
  final int skipped;
}

/// Local media index (spec 4.1, ADR 0002). Rows are reconciled by locator so
/// the app ID, progress and future playlist entries survive rescans; files
/// that disappear are marked unavailable, never silently deleted.
class MediaLibraryRepository {
  MediaLibraryRepository(
    this._db,
    this._store,
    this._importer, {
    Random? random,
  }) : _random = random ?? Random.secure();

  final AppDatabase _db;
  final MediaStoreGateway _store;
  final DocumentImporter _importer;
  final Random _random;

  static const pageSize = 500;

  $MediaItemsTable get _items => _db.mediaItems;
  $PlaybackProgressTable get _progress => _db.playbackProgress;
  $HiddenFoldersTable get _hidden => _db.hiddenFolders;

  /// [watch] folder filter for imported files, which have no folder.
  static const noFolder = '';

  // ---------------------------------------------------------------------------
  // Queries

  /// Items of [kind]. Items in hidden folders are excluded unless a
  /// [folder] is given explicitly. [folder] filters to one folder; use
  /// [noFolder] for imported files that have none.
  Stream<List<LibraryEntry>> watch(
    MediaKind kind, {
    LibrarySort sort = LibrarySort.title,
    String search = '',
    String? folder,
  }) {
    final query = (folder == null ? _visible() : _joined())
      ..where(_items.kind.equalsValue(kind));
    if (folder == noFolder) {
      query.where(_items.folder.isNull());
    } else if (folder != null) {
      query.where(_items.folder.equals(folder));
    }
    final term = search.trim();
    if (term.isNotEmpty) {
      final pattern = '%${_escapeLike(term.toLowerCase())}%';
      query.where(
        _items.title.lower().like(pattern, escapeChar: r'\') |
            _items.displayName.lower().like(pattern, escapeChar: r'\'),
      );
    }
    query.orderBy([..._ordering(sort), OrderingTerm.asc(_items.id)]);
    return query.watch().map(_entries);
  }

  /// Items with saved, unfinished progress, most recent first (spec 3).
  Stream<List<LibraryEntry>> watchContinue({int limit = 10}) {
    final query = _visible()
      ..where(
        _progress.completed.equals(false) &
            _progress.positionMs.isBiggerThanValue(0) &
            _items.available.equals(true),
      )
      ..orderBy([OrderingTerm.desc(_progress.lastPlayedAt)])
      ..limit(limit);
    return query.watch().map(_entries);
  }

  Stream<List<LibraryEntry>> watchRecentlyAdded({int limit = 20}) {
    final query = _visible()
      ..where(_items.available.equals(true))
      ..orderBy([OrderingTerm.desc(_items.addedAt)])
      ..limit(limit);
    return query.watch().map(_entries);
  }

  /// Folders containing [kind], with counts and whether they are hidden.
  Stream<List<FolderSummary>> watchFolders(MediaKind kind) {
    final count = _items.id.count();
    final bytes = _items.sizeBytes.sum();
    final sample = _items.locator.max();
    final query =
        _db.selectOnly(_items).join([
            leftOuterJoin(_hidden, _hidden.folder.equalsExp(_items.folder)),
          ])
          ..addColumns([_items.folder, _hidden.folder, count, bytes, sample])
          ..where(_items.kind.equalsValue(kind))
          ..groupBy([_items.folder])
          ..orderBy([OrderingTerm.asc(_items.folder.collate(Collate.noCase))]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          FolderSummary(
            folder: r.read(_items.folder),
            count: r.read(count) ?? 0,
            totalBytes: r.read(bytes) ?? 0,
            hidden: r.read(_hidden.folder) != null,
            sampleLocator: r.read(sample),
          ),
      ],
    );
  }

  Stream<List<String>> watchHiddenFolders() =>
      (_db.select(_hidden)..orderBy([(t) => OrderingTerm.asc(t.folder)]))
          .watch()
          .map((rows) => [for (final r in rows) r.folder]);

  Future<void> hideFolder(String folder) => _db
      .into(_hidden)
      .insertOnConflictUpdate(
        HiddenFoldersCompanion.insert(folder: folder, hiddenAt: DateTime.now()),
      );

  Future<void> showFolder(String folder) =>
      (_db.delete(_hidden)..where((t) => t.folder.equals(folder))).go();

  // ---------------------------------------------------------------------------
  // Watch history

  /// Clears all watch/listen history: resume positions, "Continue" and
  /// last-played. Library, playlists and favourites are kept.
  Future<void> clearHistory() => _db.delete(_progress).go();

  /// Removes one item from history (and its resume position).
  Future<void> removeFromHistory(String mediaId) =>
      (_db.delete(_progress)..where((t) => t.mediaId.equals(mediaId))).go();

  Stream<int> watchCount() {
    final count = _items.id.count();
    final query = _db.selectOnly(_items)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<LibraryEntry?> byId(String id) async {
    final row = await (_joined()..where(_items.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _entry(row);
  }

  // ---------------------------------------------------------------------------
  // Scan (MediaStore) and import (document picker)

  Future<ScanSummary> scanMediaStore(
    Set<MediaKind> kinds, {
    void Function(int scanned)? onProgress,
  }) async {
    final scanId = DateTime.now().microsecondsSinceEpoch;
    var added = 0, updated = 0, missing = 0, restored = 0, scanned = 0;
    for (final kind in kinds) {
      for (var offset = 0; ; offset += pageSize) {
        final page = await _store.query(kind, offset: offset, limit: pageSize);
        if (page.isEmpty) break;
        final result = await _upsertPage(page, MediaOrigin.mediaStore, scanId);
        added += result.added;
        updated += result.updated;
        restored += result.restored;
        scanned += page.length;
        onProgress?.call(scanned);
        if (page.length < pageSize) break;
      }
      missing +=
          await (_db.update(_items)..where(
                (t) =>
                    t.kind.equalsValue(kind) &
                    t.origin.equalsValue(MediaOrigin.mediaStore) &
                    t.lastSeenScan.equals(scanId).not() &
                    t.available.equals(true),
              ))
              .write(const MediaItemsCompanion(available: Value(false)));
    }
    await refreshImportedAccess();
    return ScanSummary(
      added: added,
      updated: updated,
      missing: missing,
      restored: restored,
    );
  }

  /// Opens the system picker and indexes the chosen MP4/MP3 documents.
  Future<ImportSummary> importDocuments() async {
    final uris = await _importer.pickMedia();
    final records = <MediaRecord>[];
    var skipped = 0;
    for (final uri in uris) {
      final record = await _store.describe(uri);
      if (record == null) {
        skipped++;
        await _importer.release(uri);
      } else {
        records.add(record);
      }
    }
    if (records.isNotEmpty) {
      await _upsertPage(records, MediaOrigin.imported, 0);
    }
    final imported = <LibraryEntry>[];
    for (final r in records) {
      final row = await (_joined()..where(_items.locator.equals(r.uri)))
          .getSingle();
      imported.add(_entry(row));
    }
    return ImportSummary(imported: imported, skipped: skipped);
  }

  /// Imported documents stay playable only while their grant exists.
  Future<void> refreshImportedAccess() async {
    final imported = await (_db.select(
      _items,
    )..where((t) => t.origin.equalsValue(MediaOrigin.imported))).get();
    for (final item in imported) {
      final ok = await _importer.hasAccess(item.locator);
      if (ok != item.available) {
        await (_db.update(_items)..where((t) => t.id.equals(item.id))).write(
          MediaItemsCompanion(available: Value(ok)),
        );
      }
    }
  }

  /// Re-checks an item after playback failed to open it. Missing MediaStore
  /// rows and revoked document grants become unavailable; a corrupt file that
  /// still exists stays available and playback reports the error.
  Future<void> verifyAvailability(String id) async {
    final item = await (_db.select(
      _items,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (item == null) return;
    final bool present;
    if (item.origin == MediaOrigin.imported) {
      present = await _importer.hasAccess(item.locator);
    } else {
      try {
        present = await _store.describe(item.locator) != null;
      } on Exception {
        await markUnavailable(id);
        return;
      }
    }
    if (!present) await markUnavailable(id);
  }

  /// Marks an item as missing or inaccessible.
  Future<void> markUnavailable(String id) =>
      (_db.update(_items)..where((t) => t.id.equals(id))).write(
        const MediaItemsCompanion(available: Value(false)),
      );

  /// Removes an item and its progress from the library (not from the device).
  Future<void> remove(String id) async {
    final item = await (_db.select(
      _items,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (item == null) return;
    await (_db.delete(_items)..where((t) => t.id.equals(id))).go();
    if (item.origin == MediaOrigin.imported) {
      await _importer.release(item.locator);
    }
  }

  // ---------------------------------------------------------------------------

  Future<({int added, int updated, int restored})> _upsertPage(
    List<MediaRecord> page,
    MediaOrigin origin,
    int scanId,
  ) {
    return _db.transaction(() async {
      final existing = {
        for (final row in await (_db.select(
          _items,
        )..where((t) => t.locator.isIn(page.map((r) => r.uri)))).get())
          row.locator: row,
      };
      var added = 0, updated = 0, restored = 0;
      final now = DateTime.now();
      await _db.batch((batch) {
        for (final r in page) {
          final old = existing[r.uri];
          final metadata = MediaItemsCompanion(
            kind: Value(r.kind),
            title: Value(r.bestTitle),
            displayName: Value(r.displayName),
            storeId: Value(r.storeId),
            mimeType: Value(r.mimeType),
            durationMs: Value(r.durationMs),
            sizeBytes: Value(r.sizeBytes),
            folder: Value(r.folder),
            artist: Value(r.artist),
            album: Value(r.album),
            width: Value(r.width),
            height: Value(r.height),
            modifiedAt: Value(r.modifiedAt),
            available: const Value(true),
            lastSeenScan: Value(scanId),
          );
          if (old == null) {
            batch.insert(
              _items,
              metadata.copyWith(
                id: Value(_newId()),
                locator: Value(r.uri),
                origin: Value(origin),
                addedAt: Value(r.addedAt ?? now),
              ),
            );
            added++;
          } else {
            batch.update(_items, metadata, where: (t) => t.id.equals(old.id));
            if (!old.available) restored++;
            updated++;
          }
        }
      });
      return (added: added, updated: updated, restored: restored);
    });
  }

  /// Like [_joined] but without items in hidden folders. A join (not a
  /// subquery) so live queries also refresh when folders are hidden/shown.
  JoinedSelectStatement<HasResultSet, dynamic> _visible() =>
      _db.select(_items).join([
        leftOuterJoin(_progress, _progress.mediaId.equalsExp(_items.id)),
        leftOuterJoin(_hidden, _hidden.folder.equalsExp(_items.folder)),
      ])..where(_hidden.folder.isNull());

  JoinedSelectStatement<HasResultSet, dynamic> _joined() => _db
      .select(_items)
      .join([leftOuterJoin(_progress, _progress.mediaId.equalsExp(_items.id))]);

  List<OrderingTerm> _ordering(LibrarySort sort) => switch (sort) {
    LibrarySort.title => [
      OrderingTerm.asc(_items.title.collate(Collate.noCase)),
    ],
    LibrarySort.dateAdded => [OrderingTerm.desc(_items.addedAt)],
    LibrarySort.dateModified => [OrderingTerm.desc(_items.modifiedAt)],
    LibrarySort.duration => [OrderingTerm.desc(_items.durationMs)],
    LibrarySort.size => [OrderingTerm.desc(_items.sizeBytes)],
    LibrarySort.lastPlayed => [
      OrderingTerm(
        expression: _progress.lastPlayedAt,
        mode: OrderingMode.desc,
        nulls: NullsOrder.last,
      ),
    ],
  };

  List<LibraryEntry> _entries(List<TypedResult> rows) =>
      rows.map(_entry).toList();

  LibraryEntry _entry(TypedResult row) =>
      LibraryEntry(row.readTable(_items), row.readTableOrNull(_progress));

  String _newId() {
    final bytes = List<int>.generate(12, (_) => _random.nextInt(256));
    return 'm_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
