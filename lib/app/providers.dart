import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions/media_permissions.dart';
import '../core/platform/media_store.dart';
import '../core/platform/picture_in_picture.dart';
import '../features/library/data/media_library_repository.dart';
import '../features/playback/application/playback_coordinator.dart';
import '../features/playlists/data/playlist_repository.dart';
import '../features/settings/data/preferences_repository.dart';
import '../shared/data/app_database.dart';

// Long-lived services are created in `bootstrap` and injected with overrides,
// so tests can substitute fakes.

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final coordinatorProvider = Provider<PlaybackCoordinator>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final pictureInPictureProvider = Provider<PictureInPicture>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final mediaStoreProvider = Provider<MediaStoreGateway>(
  (ref) => const MethodChannelMediaStore(),
);

final documentImporterProvider = Provider<DocumentImporter>(
  (ref) => const MethodChannelDocumentImporter(),
);

final mediaPermissionsProvider = Provider<MediaPermissions>(
  (ref) => PlatformMediaPermissions(ref.watch(mediaStoreProvider)),
);

final libraryRepositoryProvider = Provider<MediaLibraryRepository>(
  (ref) => MediaLibraryRepository(
    ref.watch(databaseProvider),
    ref.watch(mediaStoreProvider),
    ref.watch(documentImporterProvider),
  ),
);

final preferencesProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.watch(databaseProvider)),
);

final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref.watch(preferencesProvider).watchThemeMode(),
);

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepository(ref.watch(databaseProvider)),
);
