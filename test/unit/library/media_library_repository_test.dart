import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/playback/data/drift_progress_store.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late FakeMediaStore store;
  late FakeDocumentImporter importer;
  late MediaLibraryRepository repo;

  setUp(() {
    db = memoryDatabase();
    store = FakeMediaStore();
    importer = FakeDocumentImporter();
    repo = MediaLibraryRepository(db, store, importer);
  });

  tearDown(() => db.close());

  Future<List<LibraryEntry>> all(
    MediaKind kind, {
    LibrarySort? sort,
    String search = '',
  }) => repo.watch(kind, sort: sort ?? LibrarySort.title, search: search).first;

  test('scan indexes videos and audio with real metadata only', () async {
    store.videos = [record(1, title: 'Holiday')];
    store.audio = [record(2, kind: MediaKind.audio, artist: 'Band')];
    final summary = await repo.scanMediaStore(MediaKind.values.toSet());
    expect(summary.added, 2);
    final videos = await all(MediaKind.video);
    expect(videos.single.item.title, 'Holiday');
    expect(videos.single.item.origin, MediaOrigin.mediaStore);
    final songs = await all(MediaKind.audio);
    // No tag title: falls back to the file name, never invented.
    expect(songs.single.item.title, 'file_2');
    expect(songs.single.item.artist, 'Band');
    expect(songs.single.item.album, isNull);
  });

  test(
    'rescan keeps stable IDs and progress while updating metadata',
    () async {
      store.videos = [record(1, title: 'Old name')];
      await repo.scanMediaStore({MediaKind.video});
      final id = (await all(MediaKind.video)).single.item.id;
      await DriftPlaybackProgressStore(db)
          .save(id, const Duration(seconds: 42), completed: false);

      store.videos = [record(1, title: 'New name', durationMs: 90000)];
      final summary = await repo.scanMediaStore({MediaKind.video});
      expect(summary.added, 0);
      expect(summary.updated, 1);
      final entry = (await all(MediaKind.video)).single;
      expect(entry.item.id, id);
      expect(entry.item.title, 'New name');
      expect(entry.item.durationMs, 90000);
      expect(entry.progress?.positionMs, 42000);
    },
  );

  test(
    'missing files are marked unavailable, not deleted, and restored',
    () async {
      store.videos = [record(1), record(2)];
      await repo.scanMediaStore({MediaKind.video});

      store.videos = [record(2)];
      final gone = await repo.scanMediaStore({MediaKind.video});
      expect(gone.missing, 1);
      final afterDelete = await all(MediaKind.video);
      expect(afterDelete, hasLength(2));
      expect(
        afterDelete.firstWhere((e) => e.item.storeId == 1).item.available,
        isFalse,
      );

      store.videos = [record(1), record(2)];
      final back = await repo.scanMediaStore({MediaKind.video});
      expect(back.restored, 1);
      expect(
        (await all(MediaKind.video)).every((e) => e.item.available),
        isTrue,
      );
    },
  );

  test('scanning one kind never marks the other kind missing', () async {
    store.videos = [record(1)];
    store.audio = [record(2, kind: MediaKind.audio)];
    await repo.scanMediaStore(MediaKind.values.toSet());
    store.audio = [];
    // Audio permission denied this time: only videos are scanned.
    await repo.scanMediaStore({MediaKind.video});
    expect((await all(MediaKind.audio)).single.item.available, isTrue);
  });

  test('large libraries are read in pages', () async {
    store.videos = [for (var i = 0; i < 1201; i++) record(i)];
    final summary = await repo.scanMediaStore({MediaKind.video});
    expect(summary.added, 1201);
    expect(store.queries, 3);
  });

  test('import indexes picked documents and skips unsupported ones', () async {
    const ok = 'content://com.android.providers.downloads.documents/document/7';
    const bad =
        'content://com.android.providers.downloads.documents/document/8';
    store.documents[ok] = record(
      7,
      kind: MediaKind.audio,
      title: 'Picked',
    ).copyWithUri(ok);
    store.documents[bad] = null;
    importer.nextPick = [ok, bad];

    final result = await repo.importDocuments();
    expect(result.imported.single.item.title, 'Picked');
    expect(result.imported.single.item.origin, MediaOrigin.imported);
    expect(result.skipped, 1);
    expect(importer.released, [bad]);
  });

  test('imported items become unavailable when their grant is gone', () async {
    const uri = 'content://docs/document/1';
    store.documents[uri] = record(1).copyWithUri(uri);
    importer.nextPick = [uri];
    await repo.importDocuments();
    importer.granted.clear();
    await repo.refreshImportedAccess();
    expect((await all(MediaKind.video)).single.item.available, isFalse);
  });

  test(
    'verifyAvailability marks a deleted MediaStore item unavailable',
    () async {
      store.videos = [record(1)];
      await repo.scanMediaStore({MediaKind.video});
      final id = (await all(MediaKind.video)).single.item.id;
      store.videos = [];
      await repo.verifyAvailability(id);
      expect((await all(MediaKind.video)).single.item.available, isFalse);
    },
  );

  test(
    'remove deletes the row and progress and releases document grants',
    () async {
      const uri = 'content://docs/document/9';
      store.documents[uri] = record(9).copyWithUri(uri);
      importer.nextPick = [uri];
      final id = (await repo.importDocuments()).imported.single.item.id;
      await DriftPlaybackProgressStore(db)
          .save(id, const Duration(seconds: 5), completed: false);
      await repo.remove(id);
      expect(await all(MediaKind.video), isEmpty);
      expect(await db.select(db.playbackProgress).get(), isEmpty);
      expect(importer.released, [uri]);
    },
  );

  test('search is case-insensitive and treats % and _ literally', () async {
    store.videos = [
      record(1, title: 'Beach Day'),
      record(2, title: '100% fun'),
      record(3, title: 'snake_case'),
    ];
    await repo.scanMediaStore({MediaKind.video});
    expect(
      (await all(MediaKind.video, search: 'beach')).single.item.storeId,
      1,
    );
    expect((await all(MediaKind.video, search: '%')).single.item.storeId, 2);
    // 'e_c' would also match "Beach" if '_' were a wildcard.
    expect((await all(MediaKind.video, search: 'e_c')).single.item.storeId, 3);
  });

  test('sorts by name, duration, size and last played', () async {
    store.videos = [
      record(1, title: 'b', durationMs: 10, sizeBytes: 300),
      record(2, title: 'A', durationMs: 30, sizeBytes: 100),
      record(3, title: 'c', durationMs: 20, sizeBytes: 200),
    ];
    await repo.scanMediaStore({MediaKind.video});
    List<int?> ids(List<LibraryEntry> l) => [for (final e in l) e.item.storeId];
    expect(ids(await all(MediaKind.video)), [2, 1, 3]);
    expect(ids(await all(MediaKind.video, sort: LibrarySort.duration)), [
      2,
      3,
      1,
    ]);
    expect(ids(await all(MediaKind.video, sort: LibrarySort.size)), [1, 3, 2]);

    final byStore = {
      for (final e in await all(MediaKind.video)) e.item.storeId: e.item.id,
    };
    final progress = DriftPlaybackProgressStore(db);
    await progress.save(
      byStore[3]!,
      const Duration(seconds: 1),
      completed: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await progress.save(
      byStore[1]!,
      const Duration(seconds: 1),
      completed: false,
    );
    expect(ids(await all(MediaKind.video, sort: LibrarySort.lastPlayed)), [
      1,
      3,
      2,
    ]);
  });

  test('continue list shows unfinished items only', () async {
    store.videos = [record(1), record(2)];
    await repo.scanMediaStore({MediaKind.video});
    final ids = [for (final e in await all(MediaKind.video)) e.item.id];
    final progress = DriftPlaybackProgressStore(db);
    await progress.save(ids[0], const Duration(seconds: 30), completed: false);
    await progress.save(ids[1], const Duration(seconds: 60), completed: true);
    final cont = await repo.watchContinue().first;
    expect(cont.single.item.id, ids[0]);
  });

  group('folders', () {
    setUp(() async {
      store.videos = [
        record(1, folder: 'DCIM/Camera/', sizeBytes: 100),
        record(2, folder: 'DCIM/Camera/', sizeBytes: 50),
        record(3, folder: 'Movies/Trips/'),
      ];
      await repo.scanMediaStore({MediaKind.video});
    });

    test('groups items by folder with counts, sizes and names', () async {
      final folders = await repo.watchFolders(MediaKind.video).first;
      expect([for (final f in folders) f.name], ['Camera', 'Trips']);
      expect(folders.first.count, 2);
      expect(folders.first.totalBytes, 150);
      expect(folders.first.path, 'DCIM/Camera/');
      expect(folders.first.sampleLocator, isNotNull);
      expect(folders.any((f) => f.hidden), isFalse);
    });

    test('hidden folders vanish from lists, continue and recent', () async {
      final camera = [
        for (final e in await all(MediaKind.video))
          if (e.item.folder == 'DCIM/Camera/') e.item.id,
      ];
      await DriftPlaybackProgressStore(db)
          .save(camera.first, const Duration(seconds: 9), completed: false);
      expect(await repo.watchContinue().first, hasLength(1));

      // Live query updates when a folder is hidden.
      final updates = repo.watch(MediaKind.video).map((l) => l.length);
      final seen = <int>[];
      final sub = updates.listen(seen.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.hideFolder('DCIM/Camera/');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(seen.first, 3);
      expect(seen.last, 1);

      expect(await repo.watchContinue().first, isEmpty);
      expect(
        (await repo.watchRecentlyAdded().first).map((e) => e.item.folder),
        ['Movies/Trips/'],
      );
      expect(
        (await repo.watchFolders(MediaKind.video).first).first.hidden,
        isTrue,
      );
      // Still reachable explicitly (e.g. from Hidden folders).
      expect(
        await repo.watch(MediaKind.video, folder: 'DCIM/Camera/').first,
        hasLength(2),
      );
      expect(await repo.watchHiddenFolders().first, ['DCIM/Camera/']);

      await repo.showFolder('DCIM/Camera/');
      expect(await all(MediaKind.video), hasLength(3));
    });

    test('imported files without a folder are listed under noFolder', () async {
      const uri = 'content://docs/document/5';
      store.documents[uri] = record(5).copyWithUri(uri);
      importer.nextPick = [uri];
      await repo.importDocuments();
      final folders = await repo.watchFolders(MediaKind.video).first;
      expect(folders.first.folder, isNull);
      expect(folders.first.name, 'Other files');
      expect(
        await repo
            .watch(MediaKind.video, folder: MediaLibraryRepository.noFolder)
            .first,
        hasLength(1),
      );
    });
  });

  test('clear history removes progress but keeps the library', () async {
    store.videos = [record(1), record(2)];
    await repo.scanMediaStore({MediaKind.video});
    final ids = [for (final e in await all(MediaKind.video)) e.item.id];
    final progress = DriftPlaybackProgressStore(db);
    await progress.save(ids[0], const Duration(seconds: 5), completed: false);
    await progress.save(ids[1], const Duration(seconds: 5), completed: false);

    await repo.removeFromHistory(ids[0]);
    expect(
      [for (final e in await repo.watchContinue().first) e.item.id],
      [ids[1]],
    );
    expect(await progress.resumePosition(ids[0]), isNull);

    await repo.clearHistory();
    expect(await repo.watchContinue().first, isEmpty);
    expect(await all(MediaKind.video), hasLength(2));
  });
}
