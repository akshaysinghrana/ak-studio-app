import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/playback/data/drift_queue_store.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/features/playback/domain/play_queue.dart';
import 'package:video_music_app/features/playlists/data/playlist_repository.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late FakeMediaStore store;
  late MediaLibraryRepository library;
  late PlaylistRepository playlists;
  late List<String> ids; // media IDs for record(1..4)

  setUp(() async {
    db = memoryDatabase();
    store = FakeMediaStore()
      ..videos = [
        for (var i = 1; i <= 4; i++)
          record(i, title: 'v$i', durationMs: i * 1000),
      ];
    library = MediaLibraryRepository(db, store, FakeDocumentImporter());
    playlists = PlaylistRepository(db);
    await library.scanMediaStore({MediaKind.video});
    final all = await library.watch(MediaKind.video).first;
    ids = [for (final e in all) e.item.id];
  });

  tearDown(() => db.close());

  Future<List<String>> titles(String playlistId) async => [
    for (final i in await playlists.watchItems(playlistId).first)
      i.media.item.title,
  ];

  test('create, rename, add and summarise', () async {
    final id = await playlists.create('  Road trip  ');
    await playlists.addMedia(id, [ids[0], ids[2]]);
    await playlists.rename(id, 'Trip');
    final summary = (await playlists.watchPlaylists().first).single;
    expect(summary.playlist.name, 'Trip');
    expect(summary.count, 2);
    expect(summary.totalDurationMs, 4000);
    expect(await titles(id), ['v1', 'v3']);
  });

  test('empty name becomes a neutral default', () async {
    final id = await playlists.create('   ');
    expect(
      (await playlists.watchPlaylist(id).first)!.name,
      'Untitled playlist',
    );
  });

  test(
    'duplicates are rejected by default and allowed when confirmed',
    () async {
      final id = await playlists.create('A');
      await playlists.addMedia(id, [ids[0]]);
      final rejected = await playlists.addMedia(id, [ids[0], ids[1], ids[1]]);
      expect(rejected.added, 1);
      expect(rejected.duplicates, 2);
      final forced = await playlists.addMedia(id, [
        ids[0],
      ], allowDuplicates: true);
      expect(forced.added, 1);
      expect(await titles(id), ['v1', 'v2', 'v1']);
    },
  );

  test('reorder and remove keep a dense order', () async {
    final id = await playlists.create('A');
    await playlists.addMedia(id, ids);
    await playlists.moveEntry(id, 3, 0);
    expect(await titles(id), ['v4', 'v1', 'v2', 'v3']);
    final items = await playlists.watchItems(id).first;
    await playlists.removeEntry(id, items[1].entryId);
    expect(await titles(id), ['v4', 'v2', 'v3']);
    final rows = await db.select(db.playlistEntries).get();
    expect(rows.map((r) => r.orderIndex).toSet(), {0, 1, 2});
  });

  test('missing media stays in the playlist, marked unavailable', () async {
    final id = await playlists.create('A');
    await playlists.addMedia(id, ids);
    store.videos = store.videos.sublist(1);
    await library.scanMediaStore({MediaKind.video});
    final items = await playlists.watchItems(id).first;
    expect(items, hasLength(4));
    expect(items.first.media.item.available, isFalse);
  });

  test('deleting a playlist removes its entries but not media', () async {
    final id = await playlists.create('A');
    await playlists.addMedia(id, ids);
    await playlists.delete(id);
    expect(await db.select(db.playlistEntries).get(), isEmpty);
    expect(await library.watch(MediaKind.video).first, hasLength(4));
  });

  test('save queue as playlist skips duplicate queue entries', () async {
    final (id, result) = await playlists.saveAsPlaylist('Queue', [
      ids[0],
      ids[1],
      ids[0],
    ]);
    expect(result.added, 2);
    expect(result.duplicates, 1);
    expect(await titles(id), ['v1', 'v2']);
  });

  test('favourites toggle and list newest first', () async {
    expect(await playlists.toggleFavorite(ids[0]), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(await playlists.toggleFavorite(ids[1]), isTrue);
    expect(await playlists.watchIsFavorite(ids[0]).first, isTrue);
    final favs = await playlists.watchFavorites().first;
    expect([for (final f in favs) f.item.title], ['v2', 'v1']);
    expect(await playlists.toggleFavorite(ids[0]), isFalse);
    expect(await playlists.watchIsFavorite(ids[0]).first, isFalse);
  });

  group('DriftQueueStore', () {
    QueueEntry entry(String entryId, int i) => QueueEntry(
      entryId: entryId,
      media: MediaSource(
        id: ids[i],
        title: 'v${i + 1}',
        locator: 'x',
        kind: MediaKind.video,
      ),
    );

    test('round-trips order, current item, repeat and shuffle state', () async {
      final queueStore = DriftQueueStore(db);
      final queue = PlayQueue.of(
        [entry('a', 0), entry('b', 1), entry('c', 2), entry('dup', 0)],
        currentIndex: 2,
        repeat: QueueRepeat.all,
        unshuffled: ['b', 'a', 'c', 'dup'],
      );
      await queueStore.save(queue);
      final restored = (await queueStore.restore())!;
      expect(
        [for (final e in restored.entries) e.entryId],
        ['a', 'b', 'c', 'dup'],
      );
      expect(restored.current!.entryId, 'c');
      expect(restored.repeat, QueueRepeat.all);
      expect(restored.unshuffled, ['b', 'a', 'c', 'dup']);
      // Duplicates of the same media are preserved in the queue.
      expect(restored.entries.last.media.id, ids[0]);
    });

    test(
      'unavailable media is dropped on restore; unknown IDs not saved',
      () async {
        final queueStore = DriftQueueStore(db);
        await queueStore.save(
          PlayQueue.of([
            entry('a', 0),
            entry('b', 1),
            QueueEntry(
              entryId: 'debug',
              media: const MediaSource(
                id: '/sdcard/x.mp4',
                title: 'x',
                locator: '/sdcard/x.mp4',
                kind: MediaKind.video,
              ),
            ),
          ]),
        );
        await library.markUnavailable(ids[1]);
        final restored = (await queueStore.restore())!;
        expect([for (final e in restored.entries) e.entryId], ['a']);
      },
    );

    test('nothing saved restores to null', () async {
      expect(await DriftQueueStore(db).restore(), isNull);
    });
  });
}
