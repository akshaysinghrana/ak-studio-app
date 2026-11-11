import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions/media_permissions.dart';
import '../core/platform/download_service.dart';
import '../core/platform/media_store.dart';
import '../core/platform/picture_in_picture.dart';
import '../core/platform/youtube_dl.dart';
import '../features/account/data/auth_repository.dart';
import '../features/library/data/media_library_repository.dart';
import '../features/playback/application/playback_coordinator.dart';
import '../features/player/domain/subtitles.dart';
import '../features/playlists/data/playlist_repository.dart';
import '../features/settings/data/preferences_repository.dart';
import '../features/sync/application/sync_service.dart';
import '../features/sync/data/remote_store.dart';
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

/// On-device yt-dlp extractor for YouTube/Facebook/Instagram/... links.
final youtubeDlProvider = Provider<YoutubeDlGateway>(
  (ref) => MethodChannelYoutubeDl(),
);

/// Foreground service that keeps link downloads alive in the background.
final downloadServiceProvider = Provider<DownloadServiceGateway>(
  (ref) => const MethodChannelDownloadService(),
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

/// Not configured unless bootstrap found real Firebase options.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const UnconfiguredAuthRepository(),
);

/// Null when accounts are not configured for this build.
final remoteStoreProvider = Provider<RemoteStore?>((ref) => null);

final syncServiceProvider = Provider<SyncService?>((ref) {
  final remote = ref.watch(remoteStoreProvider);
  return remote == null
      ? null
      : SyncService(ref.watch(databaseProvider), remote);
});

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final brightnessGestureProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).watchBrightnessGesture(),
);

final volumeGestureProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).watchVolumeGesture(),
);

final subtitleSizeProvider = StreamProvider<SubtitleSize>(
  (ref) => ref.watch(preferencesProvider).watchSubtitleSize(),
);
