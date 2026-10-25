// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:video_music_app/shared/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // A realistic v1 library row, its progress and a preference must survive
    // the v1 -> v2 upgrade unchanged.
    const item = (
      id: 'm_1',
      kind: 'video',
      title: 'Holiday',
      locator: 'content://media/external/video/media/1',
      origin: 'mediaStore',
      addedAt: '2026-01-01T00:00:00.000Z',
    );
    final oldMediaItemsData = <v1.MediaItemsData>[
      v1.MediaItemsData(
        id: item.id,
        kind: item.kind,
        title: item.title,
        locator: item.locator,
        origin: item.origin,
        durationMs: 60000,
        addedAt: item.addedAt,
        available: 1,
        lastSeenScan: 7,
      ),
    ];
    final expectedNewMediaItemsData = <v2.MediaItemsData>[
      v2.MediaItemsData(
        id: item.id,
        kind: item.kind,
        title: item.title,
        locator: item.locator,
        origin: item.origin,
        durationMs: 60000,
        addedAt: item.addedAt,
        available: 1,
        lastSeenScan: 7,
      ),
    ];

    const at = '2026-02-01T10:00:00.000Z';
    final oldPlaybackProgressData = <v1.PlaybackProgressData>[
      const v1.PlaybackProgressData(
        mediaId: 'm_1',
        positionMs: 42000,
        completed: 0,
        lastPlayedAt: at,
        updatedAt: at,
      ),
    ];
    final expectedNewPlaybackProgressData = <v2.PlaybackProgressData>[
      const v2.PlaybackProgressData(
        mediaId: 'm_1',
        positionMs: 42000,
        completed: 0,
        lastPlayedAt: at,
        updatedAt: at,
      ),
    ];

    final oldUserPreferencesData = <v1.UserPreferencesData>[
      const v1.UserPreferencesData(
        key: 'playback.continueVideoAudioInBackground',
        value: 'true',
        updatedAt: at,
        syncEligible: 1,
      ),
    ];
    final expectedNewUserPreferencesData = <v2.UserPreferencesData>[
      const v2.UserPreferencesData(
        key: 'playback.continueVideoAudioInBackground',
        value: 'true',
        updatedAt: at,
        syncEligible: 1,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.mediaItems, oldMediaItemsData);
        batch.insertAll(oldDb.playbackProgress, oldPlaybackProgressData);
        batch.insertAll(oldDb.userPreferences, oldUserPreferencesData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewMediaItemsData,
          await newDb.select(newDb.mediaItems).get(),
        );
        expect(
          expectedNewPlaybackProgressData,
          await newDb.select(newDb.playbackProgress).get(),
        );
        expect(
          expectedNewUserPreferencesData,
          await newDb.select(newDb.userPreferences).get(),
        );
      },
    );
  });
}
