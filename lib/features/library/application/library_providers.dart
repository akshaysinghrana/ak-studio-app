import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/permissions/media_permissions.dart';
import '../../playback/domain/media_source.dart';
import '../data/media_library_repository.dart';

typedef LibraryQuery = ({
  MediaKind kind,
  LibrarySort sort,
  String search,
  String? folder,
});

final libraryProvider = StreamProvider.autoDispose
    .family<List<LibraryEntry>, LibraryQuery>(
      (ref, q) => ref
          .watch(libraryRepositoryProvider)
          .watch(q.kind, sort: q.sort, search: q.search, folder: q.folder),
    );

final foldersProvider = StreamProvider.autoDispose
    .family<List<FolderSummary>, MediaKind>(
      (ref, kind) => ref.watch(libraryRepositoryProvider).watchFolders(kind),
    );

final hiddenFoldersProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchHiddenFolders(),
);

final folderViewProvider = StreamProvider.autoDispose.family<bool, MediaKind>(
  (ref, kind) => ref.watch(preferencesProvider).watchFolderView(kind.name),
);

final gridLayoutProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(preferencesProvider).watchGridLayout(),
);

final continueProvider = StreamProvider.autoDispose<List<LibraryEntry>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchContinue(),
);

final recentlyAddedProvider = StreamProvider.autoDispose<List<LibraryEntry>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchRecentlyAdded(),
);

final libraryCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(libraryRepositoryProvider).watchCount(),
);

/// Cached thumbnail path per locator (the platform also caches on disk).
final thumbnailProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, uri) => ref.watch(mediaStoreProvider).thumbnail(uri),
);

final mediaAccessProvider =
    FutureProvider.autoDispose<Map<MediaKind, MediaAccess>>((ref) async {
      final permissions = ref.watch(mediaPermissionsProvider);
      return {
        for (final kind in MediaKind.values)
          kind: await permissions.status(kind),
      };
    });

enum ScanStatus { idle, requestingPermission, scanning, done, noAccess, failed }

class ScanState {
  const ScanState({
    this.status = ScanStatus.idle,
    this.scanned = 0,
    this.summary,
    this.access = const {},
    this.error,
  });

  final ScanStatus status;
  final int scanned;
  final ScanSummary? summary;
  final Map<MediaKind, MediaAccess> access;
  final String? error;

  bool get busy =>
      status == ScanStatus.requestingPermission ||
      status == ScanStatus.scanning;

  bool get permanentlyDenied =>
      access.values.any((a) => a == MediaAccess.permanentlyDenied);

  bool get limited => access.values.any((a) => a == MediaAccess.limited);
}

/// Runs a library scan, asking for media permission only at this moment
/// (spec 3 first-launch journey, 4.1).
class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();

  Future<void> scan() async {
    if (state.busy) return;
    state = const ScanState(status: ScanStatus.requestingPermission);
    final access = await ref.read(mediaPermissionsProvider).request();
    ref.invalidate(mediaAccessProvider);
    final kinds = {
      for (final e in access.entries)
        if (e.value == MediaAccess.granted || e.value == MediaAccess.limited)
          e.key,
    };
    if (kinds.isEmpty) {
      state = ScanState(status: ScanStatus.noAccess, access: access);
      return;
    }
    state = ScanState(status: ScanStatus.scanning, access: access);
    try {
      final summary = await ref
          .read(libraryRepositoryProvider)
          .scanMediaStore(
            kinds,
            onProgress: (n) => state = ScanState(
              status: ScanStatus.scanning,
              scanned: n,
              access: access,
            ),
          );
      state = ScanState(
        status: ScanStatus.done,
        summary: summary,
        scanned: state.scanned,
        access: access,
      );
    } on Exception catch (e) {
      state = ScanState(status: ScanStatus.failed, access: access, error: '$e');
    }
  }
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);
