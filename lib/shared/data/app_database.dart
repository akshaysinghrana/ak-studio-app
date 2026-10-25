import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/playback/domain/media_source.dart';

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

@DriftDatabase(tables: [MediaItems, PlaybackProgress, UserPreferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open() : super(driftDatabase(name: 'unified_media_player'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
