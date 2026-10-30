import 'dart:async';

import 'package:drift/native.dart';
import 'package:video_music_app/features/account/data/auth_repository.dart';
import 'package:video_music_app/core/permissions/media_permissions.dart';
import 'package:video_music_app/core/platform/media_store.dart';
import 'package:video_music_app/features/library/domain/media_record.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/shared/data/app_database.dart';

AppDatabase memoryDatabase() => AppDatabase(NativeDatabase.memory());

MediaRecord record(
  int id, {
  MediaKind kind = MediaKind.video,
  String? title,
  int durationMs = 60000,
  int sizeBytes = 1000,
  String? artist,
  DateTime? addedAt,
  String? folder,
}) => MediaRecord(
  uri:
      'content://media/external/${kind == MediaKind.video ? 'video' : 'audio'}/media/$id',
  kind: kind,
  storeId: id,
  displayName: 'file_$id.${kind == MediaKind.video ? 'mp4' : 'mp3'}',
  title: title,
  mimeType: kind == MediaKind.video ? 'video/mp4' : 'audio/mpeg',
  durationMs: durationMs,
  sizeBytes: sizeBytes,
  artist: artist,
  folder: folder,
  addedAt: addedAt ?? DateTime.utc(2026, 1, 1).add(Duration(minutes: id)),
);

/// In-memory MediaStore. Tests mutate [videos]/[audio] between scans.
class FakeMediaStore implements MediaStoreGateway {
  List<MediaRecord> videos = [];
  List<MediaRecord> audio = [];
  final Map<String, MediaRecord?> documents = {};
  int queries = 0;

  /// The next this-many queries return no rows, as Android briefly does
  /// right after an app update.
  int emptyQueries = 0;

  @override
  Future<int> sdkInt() async => 36;

  @override
  Future<List<MediaRecord>> query(
    MediaKind kind, {
    int offset = 0,
    int limit = 500,
  }) async {
    queries++;
    if (emptyQueries > 0) {
      emptyQueries--;
      return const [];
    }
    final all = kind == MediaKind.video ? videos : audio;
    return all.skip(offset).take(limit).toList();
  }

  @override
  Future<MediaRecord?> describe(String uri) async {
    if (documents.containsKey(uri)) return documents[uri];
    for (final r in [...videos, ...audio]) {
      if (r.uri == uri) return r;
    }
    return null;
  }

  @override
  Future<String?> thumbnail(String uri, {int size = 256}) async => null;

  final List<(List<String>, bool)> deleted = [];
  bool confirmDelete = true;

  @override
  Future<bool> deleteMedia(List<String> uris, {required bool trash}) async {
    if (!confirmDelete) return false;
    deleted.add((uris, trash));
    videos = videos.where((r) => !uris.contains(r.uri)).toList();
    audio = audio.where((r) => !uris.contains(r.uri)).toList();
    return true;
  }

  @override
  Future<bool> isTrashSupported() async => true;

  @override
  Stream<void> changes() => const Stream.empty();
}

class FakeDocumentImporter implements DocumentImporter {
  List<String> nextPick = [];
  final Set<String> granted = {};
  final List<String> released = [];

  @override
  Future<List<String>> pickMedia() async {
    granted.addAll(nextPick);
    return nextPick;
  }

  @override
  Future<String?> pickSubtitle() async => null;

  @override
  Future<String> readText(String uri) async => '';

  @override
  Future<void> release(String uri) async {
    granted.remove(uri);
    released.add(uri);
  }

  @override
  Future<bool> hasAccess(String uri) async => granted.contains(uri);
}

class FakeMediaPermissions implements MediaPermissions {
  FakeMediaPermissions(this.result);

  Map<MediaKind, MediaAccess> result;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<MediaAccess> status(MediaKind kind) async => result[kind]!;

  @override
  Future<Map<MediaKind, MediaAccess>> request() async {
    requests++;
    return result;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.password = 'secret1', this.googleCancels = false});

  final String password;

  /// Simulates the user closing Google's account picker.
  final bool googleCancels;
  final _users = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  bool get isConfigured => true;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _users.stream;
  }

  @override
  AppUser? get currentUser => _current;

  @override
  Future<AppUser> signIn(String email, String password) async {
    if (password != this.password) {
      throw const AuthFailure('Email or password is incorrect.');
    }
    _current = AppUser(
      uid: 'uid-1',
      email: email,
      methods: const {SignInMethod.password},
    );
    _users.add(_current);
    return _current!;
  }

  @override
  Future<AppUser> register(String email, String password) =>
      signIn(email, password);

  @override
  Future<AppUser> signInWithGoogle() async {
    if (googleCancels) {
      throw const AuthFailure(
        'Google sign-in was cancelled.',
        code: 'canceled',
      );
    }
    _current = const AppUser(
      uid: 'uid-g',
      email: 'g@example.com',
      displayName: 'Google User',
      methods: {SignInMethod.google},
    );
    _users.add(_current);
    return _current!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {
    _current = null;
    _users.add(null);
  }

  @override
  Future<void> deleteAccount({
    String? password,
    Future<void> Function()? beforeDelete,
  }) async {
    await beforeDelete?.call();
    await signOut();
  }
}
