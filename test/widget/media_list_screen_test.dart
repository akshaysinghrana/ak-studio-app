import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/app/providers.dart';
import 'package:video_music_app/core/permissions/media_permissions.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/library/presentation/media_list_screen.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/features/settings/data/preferences_repository.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../support/fakes.dart';

/// Drift streams complete on the real event loop, not the fake test clock.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

void main() {
  late AppDatabase db;
  late FakeMediaStore store;

  setUp(() {
    db = memoryDatabase();
    store = FakeMediaStore();
  });

  Future<void> pump(WidgetTester tester, MediaKind kind) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          mediaStoreProvider.overrideWithValue(store),
          documentImporterProvider.overrideWithValue(FakeDocumentImporter()),
          mediaPermissionsProvider.overrideWithValue(
            FakeMediaPermissions({
              MediaKind.video: MediaAccess.granted,
              MediaKind.audio: MediaAccess.granted,
            }),
          ),
        ],
        child: MaterialApp(home: MediaListScreen(kind: kind)),
      ),
    );
    await settle(tester);
  }

  /// List-mode tests: "All" items, list layout.
  Future<void> allItemsAsList(WidgetTester tester, MediaKind kind) =>
      tester.runAsync(() async {
        final prefs = PreferencesRepository(db);
        await prefs.setFolderView(kind.name, false);
        await prefs.setGridLayout(false);
      });

  Future<void> index(WidgetTester tester) => tester.runAsync(
    () => MediaLibraryRepository(
      db,
      store,
      FakeDocumentImporter(),
    ).scanMediaStore(MediaKind.values.toSet()),
  );

  // In-memory databases are not closed: closing inside the widget tester
  // deadlocks on drift's stream cleanup, which runs on the fake clock.
  // Unmounting and advancing that clock lets the cleanup timer fire.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('empty library offers scan and file picking', (tester) async {
    await pump(tester, MediaKind.video);
    expect(find.text('No videos yet'), findsOneWidget);
    expect(find.text('Scan library'), findsOneWidget);
    expect(find.text('Choose files'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('lists items with real metadata and hides missing files', (
    tester,
  ) async {
    store.videos = [
      record(
        1,
        title: 'Holiday',
        durationMs: 125000,
        sizeBytes: 5 * 1024 * 1024,
      ),
      record(2, title: 'Gone'),
    ];
    await index(tester);
    store.videos = [store.videos.first];
    await index(tester);
    await allItemsAsList(tester, MediaKind.video);
    await pump(tester, MediaKind.video);

    expect(find.text('Holiday'), findsOneWidget);
    expect(find.text('02:05 · 5.0 MB'), findsOneWidget);
    // Files deleted outside the app are not listed.
    expect(find.text('Gone'), findsNothing);
    await unmount(tester);
  });

  testWidgets('music shows artist only when tagged, and search filters', (
    tester,
  ) async {
    store.audio = [
      record(1, kind: MediaKind.audio, title: 'Song A', artist: 'Band'),
      record(2, kind: MediaKind.audio, title: 'Song B', durationMs: 61000),
    ];
    await index(tester);
    await allItemsAsList(tester, MediaKind.audio);
    await pump(tester, MediaKind.audio);
    expect(find.text('Band · 01:00'), findsOneWidget);
    expect(find.text('01:01'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'song b');
    await settle(tester);
    expect(find.text('Song A'), findsNothing);
    expect(find.text('Song B'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('large text (2x) renders without layout overflow', (
    tester,
  ) async {
    store.videos = [
      record(
        1,
        title: 'A rather long video title that wraps',
        durationMs: 3725000,
      ),
    ];
    await index(tester);
    // Grid cards (the default "All videos" layout) at 2x text.
    await tester.runAsync(
      () =>
          PreferencesRepository(db).setFolderView(MediaKind.video.name, false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          mediaStoreProvider.overrideWithValue(store),
          documentImporterProvider.overrideWithValue(FakeDocumentImporter()),
          mediaPermissionsProvider.overrideWithValue(
            FakeMediaPermissions({
              MediaKind.video: MediaAccess.granted,
              MediaKind.audio: MediaAccess.granted,
            }),
          ),
        ],
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(home: MediaListScreen(kind: MediaKind.video)),
        ),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('A rather long'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'folders view groups videos; hiding a folder moves it to Hidden',
    (tester) async {
      store.videos = [
        record(1, title: 'Beach', folder: 'DCIM/Camera/'),
        record(2, title: 'Party', folder: 'DCIM/Camera/'),
        record(3, title: 'Trip', folder: 'Movies/Trips/'),
      ];
      await index(tester);
      await pump(tester, MediaKind.video);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      expect(find.textContaining('2 videos'), findsOneWidget);

      await tester.tap(find.byTooltip('Folder options for Camera'));
      // Let the popup finish opening (it ignores taps while animating).
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide folder'));
      await tester.pump(const Duration(milliseconds: 500));
      await settle(tester);
      expect(find.text('Camera'), findsNothing);
      expect(find.text('Hidden folders (1)'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // "All videos" no longer lists the hidden folder's items.
      await tester.tap(find.text('All videos'));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await settle(tester);
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('Beach'), findsNothing);
      await unmount(tester);
    },
  );

  testWidgets('select files, select all, and offer bulk delete', (
    tester,
  ) async {
    store.videos = [record(1, title: 'Holiday'), record(2, title: 'Party')];
    await index(tester);
    await allItemsAsList(tester, MediaKind.video);
    await pump(tester, MediaKind.video);

    await tester.longPress(find.text('Holiday'));
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Select all'));
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete selected'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 files?'), findsOneWidget);
    await unmount(tester);
  });
}
