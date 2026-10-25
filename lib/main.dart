import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'core/platform/media_store.dart';
import 'features/account/data/auth_repository.dart';
import 'core/platform/picture_in_picture.dart';
import 'features/library/data/media_library_repository.dart';
import 'features/playback/application/playback_coordinator.dart';
import 'features/playback/data/drift_progress_store.dart';
import 'features/playback/data/drift_queue_store.dart';
import 'features/playback/domain/media_source.dart';
import 'features/settings/data/preferences_repository.dart';
import 'features/sync/application/sync_service.dart';
import 'features/sync/data/remote_store.dart';
import 'firebase_options.dart';
import 'shared/data/app_database.dart';

/// Debug-only: `--dart-define=UMP_DEBUG_AUTOLOAD=/path/a.mp4;/path/b.mp3`
/// queues files on start and opens the engine screen so device test scripts
/// can skip the system picker. Ignored in profile/release builds.
const _debugAutoload = String.fromEnvironment('UMP_DEBUG_AUTOLOAD');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();

  // Accounts only when this build has a real Firebase project (ADR 0003);
  // otherwise guest mode, and the UI says accounts are not set up.
  AuthRepository auth = const UnconfiguredAuthRepository();
  RemoteStore? remote;
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions != null) {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
      auth = FirebaseAuthRepository(FirebaseAuth.instance);
      remote = FirestoreRemoteStore(FirebaseFirestore.instance);
    } catch (e) {
      debugPrint('Firebase unavailable, continuing as guest: $e');
    }
  }
  final library = MediaLibraryRepository(
    db,
    const MethodChannelMediaStore(),
    const MethodChannelDocumentImporter(),
  );
  final preferences = PreferencesRepository(db);
  final coordinator = await PlaybackCoordinator.init(
    progressStore: DriftPlaybackProgressStore(db),
    queueStore: DriftQueueStore(db),
    onLoadError: (media) => library.verifyAvailability(media.id),
    artworkFor: (media) async {
      final path = await const MethodChannelMediaStore().thumbnail(
        media.locator,
        size: 512,
      );
      return path == null ? null : Uri.file(path);
    },
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
  final router = buildRouter(
    initialLocation: autoload ? Routes.debugEngine : Routes.home,
  );
  // Tapping the media notification opens Now Playing (spec 6.1).
  AudioService.notificationClicked.listen((clicked) {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (clicked &&
        !coordinator.playQueue.value.isEmpty &&
        path != Routes.player &&
        path != Routes.debugEngine) {
      router.push(Routes.player);
    }
  });
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        coordinatorProvider.overrideWithValue(coordinator),
        pictureInPictureProvider.overrideWithValue(PictureInPicture()),
        libraryRepositoryProvider.overrideWithValue(library),
        preferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(auth),
        remoteStoreProvider.overrideWithValue(remote),
      ],
      child: MediaPlayerApp(router: router),
    ),
  );

  if (!autoload) {
    // Restored paused at the saved position; never auto-plays (spec 7.1).
    await coordinator.restoreQueue();
  }

  // Background sync on start for a signed-in user with sync on; failures are
  // recorded and never block playback.
  final user = auth.currentUser;
  if (user != null && remote != null) {
    final sync = SyncService(db, remote);
    if (await sync.syncUserId() == user.uid) {
      unawaited(sync.sync(user.uid).then((_) {}, onError: (_) {}));
    }
  }

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
