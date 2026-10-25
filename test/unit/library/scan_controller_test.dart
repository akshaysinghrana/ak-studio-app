import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/app/providers.dart';
import 'package:video_music_app/core/permissions/media_permissions.dart';
import 'package:video_music_app/features/library/application/library_providers.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/shared/data/app_database.dart';

import '../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late FakeMediaStore store;

  setUp(() {
    db = memoryDatabase();
    store = FakeMediaStore()
      ..videos = [record(1)]
      ..audio = [record(2, kind: MediaKind.audio)];
  });
  tearDown(() => db.close());

  ProviderContainer container(FakeMediaPermissions permissions) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        mediaStoreProvider.overrideWithValue(store),
        documentImporterProvider.overrideWithValue(FakeDocumentImporter()),
        mediaPermissionsProvider.overrideWithValue(permissions),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<int> count(ProviderContainer c) =>
      c.read(libraryRepositoryProvider).watchCount().first;

  test('asks for permission only when scanning, then indexes', () async {
    final perms = FakeMediaPermissions({
      MediaKind.video: MediaAccess.granted,
      MediaKind.audio: MediaAccess.granted,
    });
    final c = container(perms);
    expect(perms.requests, 0);
    await c.read(scanControllerProvider.notifier).scan();
    expect(perms.requests, 1);
    expect(c.read(scanControllerProvider).status, ScanStatus.done);
    expect(c.read(scanControllerProvider).summary!.added, 2);
    expect(await count(c), 2);
  });

  test('scans only the kinds that were allowed', () async {
    final c = container(
      FakeMediaPermissions({
        MediaKind.video: MediaAccess.limited,
        MediaKind.audio: MediaAccess.denied,
      }),
    );
    await c.read(scanControllerProvider.notifier).scan();
    final state = c.read(scanControllerProvider);
    expect(state.status, ScanStatus.done);
    expect(state.limited, isTrue);
    expect(state.summary!.added, 1);
  });

  test('denial leaves the library untouched and reports no access', () async {
    final c = container(
      FakeMediaPermissions({
        MediaKind.video: MediaAccess.permanentlyDenied,
        MediaKind.audio: MediaAccess.denied,
      }),
    );
    await c.read(scanControllerProvider.notifier).scan();
    final state = c.read(scanControllerProvider);
    expect(state.status, ScanStatus.noAccess);
    expect(state.permanentlyDenied, isTrue);
    expect(await count(c), 0);
  });
}
