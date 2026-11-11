import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/platform/media_store.dart';
import '../../../shared/data/app_database.dart';
import '../../playback/domain/media_source.dart';
import '../domain/media_record.dart';

enum LibrarySort { title, dateAdded, dateModified, duration, size, lastPlayed }

enum FolderSort { name, itemCount, size, recent }

/// Sorts folders in memory (folder lists are small).
List<FolderSummary> sortFolders(List<FolderSummary> folders, FolderSort sort) {
  final list = [...folders];
  int byName(FolderSummary a, FolderSummary b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  list.sort(switch (sort) {
    FolderSort.name => byName,
    FolderSort.itemCount => (a, b) {
      final c = b.count.compareTo(a.count);
      return c != 0 ? c : byName(a, b);
    },
    FolderSort.size => (a, b) {
      final c = b.totalBytes.compareTo(a.totalBytes);
      return c != 0 ? c : byName(a, b);
    },
    FolderSort.recent => (a, b) {
      final c = (b.latestAddedAt ?? DateTime(0)).compareTo(
        a.latestAddedAt ?? DateTime(0),
      );
      return c != 0 ? c : byName(a, b);
    },
  });
  return list;
}

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
    this.latestAddedAt,
  });

  final String? folder;
  final int count;
  final int totalBytes;
  final bool hidden;

  /// Any item in the folder, for a thumbnail.
  final String? sampleLocator;

  /// Newest item's date added, for "Recently added" folder sorting.
  final DateTime? latestAddedAt;

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
    this.emptyScanRecheckDelay = const Duration(seconds: 2),
  }) : _random = random ?? Random.secure();

  final AppDatabase _db;
  final MediaStoreGateway _store;
  final DocumentImporter _importer;
  final Random _random;

  /// How long a scan waits before asking MediaStore again when it suddenly
  /// reports no files of a kind the library has (see [scanMediaStore]).
  final Duration emptyScanRecheckDelay;

  static const pageSize = 500;

  $MediaItemsTable get _items => _db.mediaItems;
  $PlaybackProgressTable get _progress => _db.playbackProgress;
  $HiddenFoldersTable get _hidden => _db.hiddenFolders;

  /// [watch] folder filter for imported files, which have no folder.
  static const noFolder = '';

  /// Folder label grouping files saved by the in-app downloader. Matches the
  /// public relative path downloads are published into, so a later MediaStore
  /// scan reconciles the same row instead of re-filing it.
  static const downloadFolder = 'Download/AS Media/';

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
    // Missing files are not listed (playlists still show them, marked).
    final query = (folder == null ? _visible() : _joined())
      ..where(_items.kind.equalsValue(kind) & _items.available.equals(true));
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
    final latest = _items.addedAt.max();
    final query =
        _db.selectOnly(_items).join([
            leftOuterJoin(_hidden, _hidden.folder.equalsExp(_items.folder)),
          ])
          ..addColumns([
            _items.folder,
            _hidden.folder,
            count,
            bytes,
            sample,
            latest,
          ])
          ..where(_items.kind.equalsValue(kind) & _items.available.equals(true))
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
            latestAddedAt: r.read(latest),
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

  /// Visible (available, not hidden) item counts per kind.
  Stream<Map<MediaKind, int>> watchKindCounts() {
    final count = _items.id.count();
    final query =
        _db.selectOnly(_items).join([
            leftOuterJoin(_hidden, _hidden.folder.equalsExp(_items.folder)),
          ])
          ..addColumns([_items.kind, count])
          ..where(_items.available.equals(true) & _hidden.folder.isNull())
          ..groupBy([_items.kind]);
    return query.watch().map(
      (rows) => {
        for (final kind in MediaKind.values) kind: 0,
        for (final r in rows)
          _items.kind.converter.fromSql(r.read(_items.kind)!):
              r.read(count) ?? 0,
      },
    );
  }

  Stream<int> watchCount() {
    final count = _items.id.count();
    final query = _db.selectOnly(_items)
      ..addColumns([count])
      ..where(_items.available.equals(true));
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
      var seen = 0;
      for (var attempt = 0; attempt < 2; attempt++) {
        for (var offset = 0; ; offset += pageSize) {
          final page = await _store.query(
            kind,
            offset: offset,
            limit: pageSize,
          );
          if (page.isEmpty) break;
          final result = await _upsertPage(
            page,
            MediaOrigin.mediaStore,
            scanId,
          );
          added += result.added;
          updated += result.updated;
          restored += result.restored;
          scanned += page.length;
          seen += page.length;
          onProgress?.call(scanned);
          if (page.length < pageSize) break;
        }
        // Right after an app update Android can briefly answer with no rows
        // although nothing changed. Ask once more before trusting it.
        if (seen > 0 || attempt > 0 || !await _hasAvailable(kind)) break;
        await Future<void>.delayed(emptyScanRecheckDelay);
      }
      final unseen = _db.update(_items)
        ..where(
          (t) =>
              t.kind.equalsValue(kind) &
              t.origin.equalsValue(MediaOrigin.mediaStore) &
              t.lastSeenScan.equals(scanId).not() &
              t.available.equals(true),
        );
      if (seen > 0) {
        missing += await unseen.write(
          const MediaItemsCompanion(available: Value(false)),
        );
      } else {
        // Still empty: only drop items MediaStore confirms are gone.
        for (final item
            in await (_db.select(_items)..where(
                  (t) =>
                      t.kind.equalsValue(kind) &
                      t.origin.equalsValue(MediaOrigin.mediaStore) &
                      t.available.equals(true),
                ))
                .get()) {
          if (await _store.describe(item.locator) == null) {
            await markUnavailable(item.id);
            missing++;
          }
        }
      }
    }
    await refreshImportedAccess();
    return ScanSummary(
      added: added,
      updated: updated,
      missing: missing,
      restored: restored,
    );
  }

  Future<bool> _hasAvailable(MediaKind kind) async {
    final row =
        await (_db.select(_items)
              ..where(
                (t) =>
                    t.kind.equalsValue(kind) &
                    t.origin.equalsValue(MediaOrigin.mediaStore) &
                    t.available.equals(true),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
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

  /// Indexes a finished download into the library. [locator] is where the
  /// published file lives: a `content://` URI in the public Downloads folder,
  /// or a plain app-private path when publishing was not possible.
  Future<LibraryEntry> registerDownload({
    required String locator,
    required String title,
    required String displayName,
    required MediaKind kind,
    String? mimeType,
    int? sizeBytes,
    int? width,
    int? height,
    int? durationMs,
  }) async {
    final record = MediaRecord(
      uri: locator,
      kind: kind,
      displayName: displayName,
      title: title.trim().isEmpty ? null : title.trim(),
      mimeType:
          mimeType ?? (kind == MediaKind.video ? 'video/mp4' : 'audio/mpeg'),
      durationMs: durationMs,
      sizeBytes: sizeBytes,
      folder: downloadFolder,
      width: width,
      height: height,
      addedAt: DateTime.now(),
    );
    await _upsertPage([record], MediaOrigin.downloaded, 0);
    final row = await (_joined()..where(_items.locator.equals(locator)))
        .getSingle();
    return _entry(row);
  }

  /// Re-points an already-indexed download at [newLocator] after its file was
  /// moved from app-private storage into the public Downloads folder. The row
  /// keeps its id, so playback progress, playlists and favourites survive.
  /// Returns false when no row used [oldLocator] (the caller then registers
  /// the file as a new download).
  Future<bool> relocateDownload({
    required String oldLocator,
    required String newLocator,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final old = await (_db.select(
      _items,
    )..where((t) => t.locator.equals(oldLocator))).getSingleOrNull();
    if (old == null) return false;
    final existing = await (_db.select(
      _items,
    )..where((t) => t.locator.equals(newLocator))).getSingleOrNull();
    if (existing != null && existing.id != old.id) {
      // The file is already indexed under its public URI: drop the stale
      // private-path row so the library does not show a duplicate.
      await (_db.delete(_items)..where((t) => t.id.equals(old.id))).go();
      return true;
    }
    await (_db.update(_items)..where((t) => t.id.equals(old.id))).write(
      MediaItemsCompanion(
        locator: Value(newLocator),
        folder: const Value(downloadFolder),
        origin: const Value(MediaOrigin.downloaded),
        available: const Value(true),
        mimeType: Value(mimeType),
        sizeBytes: Value(sizeBytes),
      ),
    );
    return true;
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
    } else if (item.origin == MediaOrigin.downloaded &&
        !_isContentUri(item.locator)) {
      // A download that could not be published stays a plain app-private path.
      present = await _plainFileExists(item.locator);
    } else {
      // MediaStore rows: scanned files and downloads published to the public
      // Downloads folder are both content URIs.
      try {
        present = await _store.describe(item.locator) != null;
      } on Exception {
        await markUnavailable(id);
        return;
      }
    }
    if (!present) await markUnavailable(id);
  }

  /// Moves items to the system trash or deletes them permanently, then
  /// removes them from the library (with progress, playlist entries and
  /// favourites). Returns false when the user declined the system prompt.
  Future<bool> deleteFiles(
    List<LibraryItem> items, {
    required bool trash,
  }) async {
    if (items.isEmpty) return true;
    // MediaStore rows are deleted through the system prompt. That includes
    // scanned files and downloads published to the public Downloads folder;
    // only downloads left as plain app-private paths are removed directly.
    final storeItems = [
      for (final i in items)
        if (i.origin != MediaOrigin.downloaded || _isContentUri(i.locator)) i,
    ];
    if (storeItems.isNotEmpty) {
      final ok = await _store.deleteMedia([
        for (final i in storeItems) i.locator,
      ], trash: trash);
      if (!ok) return false;
    }
    final ids = [for (final i in items) i.id];
    await (_db.delete(_items)..where((t) => t.id.isIn(ids))).go();
    for (final i in items.where((i) => i.origin == MediaOrigin.imported)) {
      await _importer.release(i.locator);
    }
    for (final i in items) {
      if (i.origin != MediaOrigin.downloaded || _isContentUri(i.locator)) {
        continue;
      }
      try {
        final uri = Uri.tryParse(i.locator);
        final file = (uri != null && uri.scheme == 'file')
            ? File.fromUri(uri)
            : File(i.locator);
        if (await file.exists()) await file.delete();
      } on Exception {
        // The library row is already gone; a leftover file is harmless.
      }
    }
    return true;
  }

  /// Items of [kind] in one folder (for deleting a whole folder).
  Future<List<LibraryItem>> itemsInFolder(MediaKind kind, String? folder) =>
      (_db.select(_items)..where(
            (t) =>
                t.kind.equalsValue(kind) &
                (folder == null ? t.folder.isNull() : t.folder.equals(folder)),
          ))
          .get();

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

  static bool _isContentUri(String locator) => locator.startsWith('content://');

  /// True when a plain app-private path (or `file://` URI) still exists.
  static Future<bool> _plainFileExists(String locator) async {
    try {
      final uri = Uri.tryParse(locator);
      final file = (uri != null && uri.scheme == 'file')
          ? File.fromUri(uri)
          : File(locator);
      return await file.exists();
    } on Exception {
      return false;
    }
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
