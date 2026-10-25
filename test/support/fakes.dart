import 'package:drift/native.dart';
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
  addedAt: addedAt ?? DateTime.utc(2026, 1, 1).add(Duration(minutes: id)),
);

/// In-memory MediaStore. Tests mutate [videos]/[audio] between scans.
class FakeMediaStore implements MediaStoreGateway {
  List<MediaRecord> videos = [];
  List<MediaRecord> audio = [];
  final Map<String, MediaRecord?> documents = {};
  int queries = 0;

  @override
  Future<int> sdkInt() async => 36;

  @override
  Future<List<MediaRecord>> query(
    MediaKind kind, {
    int offset = 0,
    int limit = 500,
  }) async {
    queries++;
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
