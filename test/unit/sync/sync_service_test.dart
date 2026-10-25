import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/library/data/media_library_repository.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/features/playlists/data/playlist_repository.dart';
import 'package:video_music_app/features/settings/data/preferences_repository.dart';
import 'package:video_music_app/features/sync/application/sync_service.dart';
import 'package:video_music_app/features/sync/data/remote_store.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../../support/fakes.dart';

const uid = 'user-1';

/// One simulated phone: its own database, library and repositories.
class Device {
  Device(this.remote, {required int fileCount}) {
    db = memoryDatabase();
    store = FakeMediaStore()
      ..audio = [
        for (var i = 1; i <= fileCount; i++)
          record(
            i,
            kind: MediaKind.audio,
            title: 'Song $i',
            durationMs: i * 60000,
          ),
      ];
    library = MediaLibraryRepository(db, store, FakeDocumentImporter());
    playlists = PlaylistRepository(db);
    sync = SyncService(db, remote);
  }

  final RemoteStore remote;
  late final AppDatabase db;
  late final FakeMediaStore store;
  late final MediaLibraryRepository library;
  late final PlaylistRepository playlists;
  late final SyncService sync;

  Future<void> scan() => library.scanMediaStore({MediaKind.audio});

  Future<String> idOf(String title) async =>
      (await library.watch(MediaKind.audio, search: title).first)
          .firstWhere((e) => e.item.title == title)
          .item
          .id;

  Future<List<String>> titles(String playlistId) async => [
    for (final i in await playlists.watchItems(playlistId).first)
      i.media.item.title,
  ];
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late InMemoryRemoteStore remote;
  late Device a, b;

  setUp(() async {
    remote = InMemoryRemoteStore();
    a = Device(remote, fileCount: 3);
    b = Device(remote, fileCount: 2); // phone B lacks "Song 3"
    // Different scan order on B gives different local IDs for the same files.
    b.store.audio = b.store.audio.reversed.toList();
    await a.scan();
    await b.scan();
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('playlists sync across devices by fingerprint', () async {
    final id = await a.playlists.create('Road trip');
    await a.playlists.addMedia(id, [
      await a.idOf('Song 2'),
      await a.idOf('Song 1'),
    ]);
    await a.sync.enable(uid, attachLocalPlaylists: true);
    await a.sync.sync(uid);

    await b.sync.enable(uid, attachLocalPlaylists: false);
    final result = await b.sync.sync(uid);
    expect(result.pulled, greaterThan(0));
    expect((await b.playlists.watchPlaylist(id).first)!.name, 'Road trip');
    expect(await b.titles(id), ['Song 2', 'Song 1']);
  });

  test('no file names, paths, titles or URIs are uploaded', () async {
    final id = await a.playlists.create('Mine');
    await a.playlists.addMedia(id, [await a.idOf('Song 1')]);
    await a.playlists.toggleFavorite(await a.idOf('Song 2'));
    await a.sync.enable(uid, attachLocalPlaylists: true);
    await a.sync.sync(uid);

    final dump = remote.data.toString();
    expect(dump, isNot(contains('file_')));
    expect(dump, isNot(contains('content://')));
    expect(dump, isNot(contains('Song')));
    final entries = remote.data[uid]!['playlists']![id]!['entries'] as List;
    expect(entries.single, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(
      remote.data[uid]!['settings']?.keys ?? const [],
      isNot(contains(SyncService.syncUserKey)),
    );
  });

  test(
    'guest playlists stay local unless the user agrees to attach them',
    () async {
      await a.playlists.create('Private');
      await a.sync.enable(uid, attachLocalPlaylists: false);
      expect(await a.sync.unattachedPlaylistCount(), 1);
      await a.sync.sync(uid);
      expect(remote.data[uid]?['playlists'] ?? const {}, isEmpty);
    },
  );

  test(
    'last write wins; an older remote copy never overwrites a newer local edit',
    () async {
      final id = await a.playlists.create('v1');
      await a.sync.enable(uid, attachLocalPlaylists: true);
      await a.sync.sync(uid);
      await b.sync.enable(uid, attachLocalPlaylists: false);
      await b.sync.sync(uid);

      await tick();
      await b.playlists.rename(id, 'renamed on B');
      await b.sync.sync(uid);
      await a.sync.sync(uid);
      expect((await a.playlists.watchPlaylist(id).first)!.name, 'renamed on B');

      await tick();
      await a.playlists.rename(id, 'newer on A');
      // B syncs first with its older copy: it must not clobber A's newer edit.
      await b.sync.sync(uid);
      await a.sync.sync(uid);
      await b.sync.sync(uid);
      expect((await b.playlists.watchPlaylist(id).first)!.name, 'newer on A');
    },
  );

  test('deletions propagate; an edit after a remote deletion wins', () async {
    final id = await a.playlists.create('Temp');
    await a.sync.enable(uid, attachLocalPlaylists: true);
    await a.sync.sync(uid);
    await b.sync.enable(uid, attachLocalPlaylists: false);
    await b.sync.sync(uid);

    await a.playlists.delete(id);
    await a.sync.sync(uid);
    await b.sync.sync(uid);
    expect(await b.playlists.watchPlaylist(id).first, isNull);

    final id2 = await a.playlists.create('Keep');
    await a.sync.enable(uid, attachLocalPlaylists: true);
    await a.sync.sync(uid);
    await b.sync.sync(uid);
    await b.playlists.delete(id2);
    await b.sync.sync(uid);
    await tick();
    await a.playlists.rename(id2, 'Keep (edited)');
    await a.sync.sync(uid);
    await b.sync.sync(uid);
    expect((await b.playlists.watchPlaylist(id2).first)!.name, 'Keep (edited)');
  });

  test(
    'entries for files missing on a device are kept in the account',
    () async {
      final id = await a.playlists.create('All');
      await a.playlists.addMedia(id, [
        await a.idOf('Song 1'),
        await a.idOf('Song 3'), // not on B
      ]);
      await a.sync.enable(uid, attachLocalPlaylists: true);
      await a.sync.sync(uid);
      await b.sync.enable(uid, attachLocalPlaylists: false);
      await b.sync.sync(uid);
      expect(await b.titles(id), ['Song 1']);

      await tick();
      await b.playlists.addMedia(id, [await b.idOf('Song 2')]);
      await b.sync.sync(uid);
      await a.sync.sync(uid);
      expect(await a.titles(id), ['Song 1', 'Song 2', 'Song 3']);
    },
  );

  test('favourites sync both ways, including removal', () async {
    await a.sync.enable(uid, attachLocalPlaylists: true);
    await b.sync.enable(uid, attachLocalPlaylists: false);
    await a.playlists.toggleFavorite(await a.idOf('Song 1'));
    await a.sync.sync(uid);
    await b.sync.sync(uid);
    expect(
      await b.playlists.watchIsFavorite(await b.idOf('Song 1')).first,
      isTrue,
    );

    await tick();
    await b.playlists.toggleFavorite(await b.idOf('Song 1'));
    await b.sync.sync(uid);
    await a.sync.sync(uid);
    expect(
      await a.playlists.watchIsFavorite(await a.idOf('Song 1')).first,
      isFalse,
    );
  });

  test('sync-eligible settings follow the newest value', () async {
    await a.sync.enable(uid, attachLocalPlaylists: true);
    await b.sync.enable(uid, attachLocalPlaylists: false);
    await PreferencesRepository(a.db).setContinueVideoAudioInBackground(true);
    await a.sync.sync(uid);
    await b.sync.sync(uid);
    expect(
      await PreferencesRepository(b.db).continueVideoAudioInBackground(),
      isTrue,
    );
  });

  test('sign-out keeps local data unless removal is chosen', () async {
    final id = await a.playlists.create('Mine');
    await a.sync.enable(uid, attachLocalPlaylists: true);
    await a.sync.disable(uid);
    expect(await a.playlists.watchPlaylist(id).first, isNotNull);
    expect(await a.sync.syncUserId(), isNull);

    await a.sync.enable(uid, attachLocalPlaylists: false);
    await a.sync.disable(uid, removeAccountData: true);
    expect(await a.playlists.watchPlaylist(id).first, isNull);
  });

  test(
    'a failed sync records the error and leaves local data intact',
    () async {
      final id = await a.playlists.create('Mine');
      await a.sync.enable(uid, attachLocalPlaylists: true);
      final failing = SyncService(a.db, _FailingRemote());
      await expectLater(failing.sync(uid), throwsA(isA<StateError>()));
      final meta = await a.sync.watchMetadata(uid).first;
      expect(meta!.lastError, contains('offline'));
      expect(await a.playlists.watchPlaylist(id).first, isNotNull);
    },
  );
}

class _FailingRemote implements RemoteStore {
  @override
  Future<Map<String, Map<String, Object?>>> list(String uid, String c) =>
      throw StateError('offline');

  @override
  Future<void> putAll(
    String uid,
    String c,
    Map<String, Map<String, Object?>> d,
  ) => throw StateError('offline');

  @override
  Future<void> deleteUserData(String uid) => throw StateError('offline');
}
