import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../shared/data/app_database.dart';
import '../../sync/application/sync_service.dart';

enum SyncStatus { idle, syncing, done, failed }

class SyncState {
  const SyncState({this.status = SyncStatus.idle, this.message});

  final SyncStatus status;
  final String? message;
}

/// Runs sync in the background; failures are reported, never block playback
/// (spec 9.2).
class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  SyncService? get _sync => ref.read(syncServiceProvider);

  Future<void> syncNow() async {
    final sync = _sync;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (sync == null || user == null || state.status == SyncStatus.syncing) {
      return;
    }
    if (await sync.syncUserId() != user.uid) return;
    state = const SyncState(status: SyncStatus.syncing);
    try {
      final r = await sync.sync(user.uid);
      state = SyncState(
        status: SyncStatus.done,
        message: 'Synced: ${r.pulled} updated here, ${r.pushed} sent.',
      );
    } catch (e) {
      state = SyncState(
        status: SyncStatus.failed,
        message: 'Sync failed. Your data on this device is unchanged.',
      );
    }
  }

  /// After sign-in: enable sync for this account and run it.
  Future<void> enableAndSync({required bool attachLocalPlaylists}) async {
    final sync = _sync;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (sync == null || user == null) return;
    await sync.enable(user.uid, attachLocalPlaylists: attachLocalPlaylists);
    await syncNow();
  }

  Future<void> signOut({required bool removeAccountData}) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      await _sync?.disable(user.uid, removeAccountData: removeAccountData);
    }
    await ref.read(authRepositoryProvider).signOut();
    state = const SyncState();
  }

  /// Deletes account data in the cloud, then the account itself. Local media
  /// and playlists stay on the device, detached from the account.
  /// [password] for password accounts; Google accounts confirm with Google.
  Future<void> deleteAccount({String? password}) async {
    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    final remote = ref.read(remoteStoreProvider);
    if (user == null) return;
    // Re-authenticate first so a wrong password deletes nothing.
    await auth.deleteAccount(
      password: password,
      beforeDelete: () async => remote?.deleteUserData(user.uid),
    );
    await _sync?.disable(user.uid);
    state = const SyncState();
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

final syncMetadataProvider = StreamProvider.autoDispose<SyncMetadataRow?>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  final sync = ref.watch(syncServiceProvider);
  if (user == null || sync == null) return Stream.value(null);
  return sync.watchMetadata(user.uid);
});

final syncEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  ref.watch(syncControllerProvider);
  final user = ref.watch(authStateProvider).value;
  final sync = ref.watch(syncServiceProvider);
  if (user == null || sync == null) return false;
  return await sync.syncUserId() == user.uid;
});
