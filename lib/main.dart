import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'core/platform/media_store.dart';
import 'core/platform/picture_in_picture.dart';
import 'features/library/data/media_library_repository.dart';
import 'features/playback/application/playback_coordinator.dart';
import 'features/playback/data/drift_progress_store.dart';
import 'features/playback/domain/media_source.dart';
import 'features/settings/data/preferences_repository.dart';
import 'shared/data/app_database.dart';

/// Debug-only: `--dart-define=UMP_DEBUG_AUTOLOAD=/path/a.mp4;/path/b.mp3`
/// queues files on start and opens the engine screen so device test scripts
/// can skip the system picker. Ignored in profile/release builds.
const _debugAutoload = String.fromEnvironment('UMP_DEBUG_AUTOLOAD');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  final library = MediaLibraryRepository(
    db,
    const MethodChannelMediaStore(),
    const MethodChannelDocumentImporter(),
  );
  final preferences = PreferencesRepository(db);
  final coordinator = await PlaybackCoordinator.init(
    progressStore: DriftPlaybackProgressStore(db),
    onLoadError: (media) => library.verifyAvailability(media.id),
  );

  // Spec 8.1: the background-audio setting is persisted and restored.
  coordinator.continueVideoAudioInBackground.value = await preferences
      .continueVideoAudioInBackground();
  coordinator.continueVideoAudioInBackground.addListener(
    () => preferences.setContinueVideoAudioInBackground(
      coordinator.continueVideoAudioInBackground.value,
    ),
  );

  final autoload = kDebugMode && _debugAutoload.isNotEmpty;
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        coordinatorProvider.overrideWithValue(coordinator),
        pictureInPictureProvider.overrideWithValue(PictureInPicture()),
        libraryRepositoryProvider.overrideWithValue(library),
        preferencesProvider.overrideWithValue(preferences),
      ],
      child: MediaPlayerApp(
        router: buildRouter(
          initialLocation: autoload ? Routes.debugEngine : Routes.home,
        ),
      ),
    ),
  );

  if (autoload) {
    for (final path in _debugAutoload.split(';')) {
      final media = MediaSource.fromFile(
        path: path,
        name: path.split('/').last,
      );
      if (media != null) await coordinator.addToQueue(media);
    }
  }
}
