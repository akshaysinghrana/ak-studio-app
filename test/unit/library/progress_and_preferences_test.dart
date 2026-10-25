import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/playback/data/drift_progress_store.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/features/settings/data/preferences_repository.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../../support/fakes.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  group('DriftPlaybackProgressStore', () {
    late DriftPlaybackProgressStore store;
    late String id;

    setUp(() async {
      final media = FakeMediaStore()..videos = [record(1)];
      final repo = MediaLibraryRepository(db, media, FakeDocumentImporter());
      await repo.scanMediaStore({MediaKind.video});
      id = (await repo.watch(MediaKind.video).first).single.item.id;
      store = DriftPlaybackProgressStore(db);
    });

    test('saves and resumes integer-millisecond positions', () async {
      await store.save(
        id,
        const Duration(milliseconds: 12345),
        completed: false,
      );
      expect(
        await store.resumePosition(id),
        const Duration(milliseconds: 12345),
      );
      await store.save(id, const Duration(seconds: 20), completed: false);
      expect(await store.resumePosition(id), const Duration(seconds: 20));
    });

    test('completed items do not resume', () async {
      await store.save(id, const Duration(seconds: 59), completed: true);
      expect(await store.resumePosition(id), isNull);
    });

    test('unknown media IDs are ignored instead of failing', () async {
      await store.save(
        '/debug/path.mp4',
        const Duration(seconds: 1),
        completed: false,
      );
      expect(await store.resumePosition('/debug/path.mp4'), isNull);
    });
  });

  group('PreferencesRepository', () {
    test('background video audio defaults to off and persists', () async {
      final prefs = PreferencesRepository(db);
      expect(await prefs.continueVideoAudioInBackground(), isFalse);
      await prefs.setContinueVideoAudioInBackground(true);
      expect(
        await PreferencesRepository(db).continueVideoAudioInBackground(),
        isTrue,
      );
      final row = await db.select(db.userPreferences).getSingle();
      expect(row.syncEligible, isTrue);
    });

    test('theme defaults to dark and emits changes', () async {
      final prefs = PreferencesRepository(db);
      expect(await prefs.watchThemeMode().first, ThemeMode.dark);
      await prefs.setThemeMode(ThemeMode.light);
      expect(await prefs.watchThemeMode().first, ThemeMode.light);
    });
  });
}
