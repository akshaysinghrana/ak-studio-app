import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/playback/domain/media_source.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

/// Where a library item came from (ADR 0002).
enum MediaOrigin { mediaStore, imported }

/// Indexed local media. [id] is the app's stable ID; [locator] is the durable
/// `content://` URI and may change only through rescans (spec 4.1, 11).
@DataClassName('LibraryItem')
@TableIndex(name: 'media_items_kind_title', columns: {#kind, #title})
@TableIndex(name: 'media_items_kind_added', columns: {#kind, #addedAt})
class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<MediaKind>()();
  TextColumn get title => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get locator => text().unique()();
  TextColumn get origin => textEnum<MediaOrigin>()();
  IntColumn get storeId => integer().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get folder => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  DateTimeColumn get modifiedAt => dateTime().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();

  /// ID of the last MediaStore scan that saw this item; used to detect
  /// deleted/moved files without deleting their history.
  IntColumn get lastSeenScan => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaybackProgressRow')
@TableIndex(name: 'playback_progress_last_played', columns: {#lastPlayedAt})
class PlaybackProgress extends Table {
  TextColumn get mediaId =>
      text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get positionMs => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastPlayedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

@DataClassName('UserPreference')
class UserPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether this preference may sync to the account in Phase 6.
  BoolColumn get syncEligible => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}

/// Persisted Now Playing queue (spec 7.1): restored after process death.
@DataClassName('QueueEntryRow')
class QueueEntries extends Table {
  TextColumn get entryId => text()();
  TextColumn get mediaId =>
      text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {entryId};
}

/// Single-row queue state (id is always 0).
@DataClassName('QueueStateRow')
class QueueState extends Table {
  IntColumn get id => integer()();
  TextColumn get currentEntryId => text().nullable()();
  TextColumn get repeatMode => text().withDefault(const Constant('off'))();

  /// JSON list of entry IDs in pre-shuffle order; null when not shuffled.
  TextColumn get unshuffledJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 'local' for guest data; 'user' once synced to an account (Phase 6).
  TextColumn get ownerScope => text().withDefault(const Constant('local'))();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistEntryRow')
@TableIndex(name: 'playlist_entries_order', columns: {#playlistId, #orderIndex})
class PlaylistEntries extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId =>
      text().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get mediaId =>
      text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get mediaId =>
      text().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

/// Deletions of synced records, pushed to the account on the next sync so
/// other devices remove them too (ADR 0003).
@DataClassName('SyncTombstoneRow')
class SyncTombstones extends Table {
  /// 'playlist' or 'favorite'.
  TextColumn get kind => text()();

  /// Playlist ID, or the media fingerprint for favourites.
  TextColumn get recordId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kind, recordId, userId};
}

@DataClassName('SyncMetadataRow')
class SyncMetadata extends Table {
  TextColumn get userId => text()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    SyncTombstones,
    SyncMetadata,
    MediaItems,
    PlaybackProgress,
    UserPreferences,
    QueueEntries,
    QueueState,
    Playlists,
    PlaylistEntries,
    Favorites,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open() : super(driftDatabase(name: 'unified_media_player'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.queueEntries);
        await m.createTable(schema.queueState);
        await m.createTable(schema.playlists);
        await m.createTable(schema.playlistEntries);
        await m.createIndex(schema.playlistEntriesOrder);
        await m.createTable(schema.favorites);
      },
      from2To3: (m, schema) async {
        await m.createTable(schema.syncTombstones);
        await m.createTable(schema.syncMetadata);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
