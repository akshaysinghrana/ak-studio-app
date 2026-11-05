import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../shared/data/app_database.dart';
import '../../discover/domain/catalog.dart';
import '../../library/data/media_library_repository.dart';
import '../../playback/domain/media_source.dart';
import '../../playlists/data/playlist_repository.dart';
import '../../settings/data/preferences_repository.dart';
import '../data/download_engine.dart';
import '../domain/download_rules.dart';

sealed class DownloadRequest {
  const DownloadRequest();
}

class DownloadStarted extends DownloadRequest {
  const DownloadStarted(this.row);
  final DownloadRow row;
}

/// Already downloaded or in progress; pass `force: true` to download again.
class DownloadDuplicate extends DownloadRequest {
  const DownloadDuplicate(this.existing);
  final DownloadRow existing;
}

class DownloadRejected extends DownloadRequest {
  const DownloadRejected(this.reason);
  final String reason;
}

/// Live transfer figures that are not worth persisting.
class LiveProgress {
  const LiveProgress({this.bytesPerSecond, this.remaining});
  final double? bytesPerSecond;
  final Duration? remaining;
}

/// What a direct link serves, from a HEAD request.
class UrlInfo {
  const UrlInfo({this.mimeType, this.fileName, this.finalUrl});
  final String? mimeType;
  final String? fileName;
  final Uri? finalUrl;
}

typedef UrlProbe = Future<UrlInfo> Function(Uri url);

/// Downloads media the source permits (ADR 0004): catalogue tracks with a
/// download URL and direct MP3/MP4 links. Finished files are validated,
/// moved to `Music/AS Media` or `Movies/AS Media` and appear in the library.
class DownloadManager {
  DownloadManager({
    required this._db,
    required this._engine,
    required PreferencesRepository preferences,
    required this._library,
    required this._playlists,
    required this._refreshLibrary,
    UrlProbe? probe,
    this.libraryWait = const Duration(seconds: 20),
  }) : _prefs = preferences,
       _probe = probe ?? httpProbe(http.Client());

  final AppDatabase _db;
  final DownloadEngine _engine;
  final PreferencesRepository _prefs;
  final MediaLibraryRepository _library;
  final PlaylistRepository _playlists;
  final Future<void> Function(MediaKind kind) _refreshLibrary;
  final UrlProbe _probe;

  /// How long to wait for a finished file to appear in the library before
  /// skipping "add to playlist".
  final Duration libraryWait;

  static const downloadsPlaylist = 'Downloads';

  /// Speed and time remaining per download ID, while running.
  final live = ValueNotifier<Map<String, LiveProgress>>(const {});

  StreamSubscription<EngineUpdate>? _sub;
  bool _askedNotifications = false;
  int _counter = 0;

  $DownloadsTable get _t => _db.downloads;

  Future<void> init() async {
    _sub ??= _engine.updates.listen(_onUpdate);
    await _engine.start(
      concurrency: await _prefs.downloadConcurrency(),
      wifiOnly: await _prefs.downloadWifiOnly(),
    );
    await _reconcile();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    live.dispose();
  }

  Future<void> setConcurrency(int n) async {
    await _prefs.setDownloadConcurrency(n);
    await _engine.setConcurrency(n.clamp(1, 3));
  }

  Future<void> setWifiOnly(bool on) async {
    await _prefs.setDownloadWifiOnly(on);
    await _engine.setWifiOnly(on);
  }

  Stream<List<DownloadRow>> watchAll() => (_db.select(
    _t,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  /// Latest download per `source:sourceId`, for showing state on tracks.
  Stream<Map<String, DownloadRow>> watchBySource() => watchAll().map(
    (rows) => {for (final r in rows.reversed) '${r.source}:${r.sourceId}': r},
  );

  Stream<int> watchActiveCount() => watchAll().map(
    (rows) => rows
        .where(
          (r) =>
              r.status == DownloadStatus.running ||
              r.status == DownloadStatus.waiting ||
              r.status == DownloadStatus.paused,
        )
        .length,
  );

  // ---------------------------------------------------------------------------
  // Requests

  Future<DownloadRequest> downloadTrack(
    CatalogTrack track, {
    bool force = false,
  }) async {
    final url = track.downloadUrl;
    if (url == null) {
      return const DownloadRejected(
        'The artist has not allowed downloads of this track.',
      );
    }
    return _start(
      source: track.source.name,
      sourceId: track.id,
      url: url,
      title: track.title,
      artist: track.artist,
      kind: MediaKind.audio,
      force: force,
    );
  }

  Future<DownloadRequest> downloadUrl(
    String input, {
    String? title,
    bool force = false,
  }) async {
    final invalid = DownloadRules.validateUrl(input);
    if (invalid != null) return DownloadRejected(invalid);
    final uri = Uri.parse(input.trim());
    UrlInfo info;
    try {
      info = await _probe(uri);
    } on Exception {
      info = const UrlInfo();
    }
    final finalHost = info.finalUrl?.host;
    if (finalHost != null && DownloadRules.isBlockedHost(finalHost)) {
      return const DownloadRejected(
        'This link leads to YouTube, which cannot be downloaded.',
      );
    }
    final kind = DownloadRules.kindFor(
      mimeType: info.mimeType,
      fileName: info.fileName ?? uri.pathSegments.lastOrNull,
    );
    if (kind == null) {
      return const DownloadRejected(
        'Only direct links to MP3 or MP4 files can be downloaded.',
      );
    }
    final name = title?.trim();
    return _start(
      source: 'url',
      sourceId: uri.toString(),
      url: uri.toString(),
      title: name == null || name.isEmpty
          ? DownloadRules.titleFromUrl(
              info.fileName == null ? uri : Uri(path: info.fileName),
            )
          : name,
      kind: kind,
      force: force,
    );
  }

  Future<DownloadRequest> _start({
    required String source,
    required String sourceId,
    required String url,
    required String title,
    required MediaKind kind,
    String? artist,
    required bool force,
  }) async {
    if (!force) {
      final existing = await _existing(source, sourceId);
      if (existing != null) return DownloadDuplicate(existing);
    }
    if (!_askedNotifications) {
      _askedNotifications = true;
      await _engine.ensureNotificationPermission();
    }
    final now = DateTime.now();
    final id = 'd${now.microsecondsSinceEpoch}_${_counter++}';
    final fileName = DownloadRules.fileName(title, kind, artist: artist);
    await _db
        .into(_t)
        .insert(
          DownloadsCompanion.insert(
            id: id,
            taskId: id,
            source: source,
            sourceId: sourceId,
            url: url,
            title: title,
            artist: Value(artist),
            kind: kind,
            fileName: fileName,
            status: DownloadStatus.waiting,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final row = await _row(id);
    final ok = await _engine.enqueue(_taskFor(row!));
    if (!ok) {
      await _update(
        id,
        DownloadsCompanion(
          status: const Value(DownloadStatus.failed),
          error: const Value('The download could not be started.'),
        ),
      );
    }
    return DownloadStarted((await _row(id))!);
  }

  Future<DownloadRow?> _existing(String source, String sourceId) async {
    final rows =
        await (_db.select(_t)
              ..where(
                (t) =>
                    t.source.equals(source) &
                    t.sourceId.equals(sourceId) &
                    t.status.isInValues([
                      DownloadStatus.waiting,
                      DownloadStatus.running,
                      DownloadStatus.paused,
                      DownloadStatus.complete,
                    ]),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    for (final r in rows) {
      if (r.status != DownloadStatus.complete) return r;
      // A completed download only counts while its file still exists.
      final path = r.savedPath;
      if (path != null && await File(path).exists()) return r;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Controls

  Future<void> pause(String id) async {
    final row = await _row(id);
    if (row != null) await _engine.pause(row.taskId);
  }

  Future<void> resume(String id) async {
    final row = await _row(id);
    if (row == null) return;
    if (!await _engine.resume(row.taskId)) await retry(id);
  }

  Future<void> cancel(String id) async {
    final row = await _row(id);
    if (row == null) return;
    await _engine.cancel(row.taskId);
    await _update(
      id,
      const DownloadsCompanion(status: Value(DownloadStatus.canceled)),
    );
  }

  /// Starts a failed or canceled download again from the beginning.
  Future<void> retry(String id) async {
    final row = await _row(id);
    if (row == null) return;
    final taskId = '${id}_r${DateTime.now().millisecondsSinceEpoch}';
    await _update(
      id,
      DownloadsCompanion(
        taskId: Value(taskId),
        status: const Value(DownloadStatus.waiting),
        progress: const Value(0),
        error: const Value(null),
      ),
    );
    final ok = await _engine.enqueue(_taskFor((await _row(id))!));
    if (!ok) {
      await _update(
        id,
        const DownloadsCompanion(
          status: Value(DownloadStatus.failed),
          error: Value('The download could not be started.'),
        ),
      );
    }
  }

  /// Removes the entry from the list; a saved file stays in the library.
  Future<void> remove(String id) async {
    final row = await _row(id);
    if (row == null) return;
    if (row.status == DownloadStatus.running ||
        row.status == DownloadStatus.waiting ||
        row.status == DownloadStatus.paused) {
      await _engine.cancel(row.taskId);
    }
    await (_db.delete(_t)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearFinished() =>
      (_db.delete(_t)..where(
            (t) => t.status.isInValues([
              DownloadStatus.complete,
              DownloadStatus.canceled,
            ]),
          ))
          .go();

  /// The library item for a finished download, if indexed.
  Future<LibraryItem?> libraryItemFor(DownloadRow row) async {
    final path = row.savedPath;
    if (path == null) return null;
    final folder = DownloadRules.relativeFolder(path);
    if (folder == null) return null;
    return _library.findByFolderAndName(folder, path.split('/').last);
  }

  // ---------------------------------------------------------------------------
  // Engine updates

  EngineTask _taskFor(DownloadRow row) => EngineTask(
    taskId: row.taskId,
    url: row.url,
    fileName: row.fileName,
    displayName: row.title,
  );

  Future<DownloadRow?> _row(String id) =>
      (_db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<DownloadRow?> _rowForTask(String taskId) =>
      (_db.select(_t)..where((t) => t.taskId.equals(taskId))).getSingleOrNull();

  Future<void> _update(String id, DownloadsCompanion values) =>
      (_db.update(_t)..where((t) => t.id.equals(id))).write(
        values.copyWith(updatedAt: Value(DateTime.now())),
      );

  Future<void> _onUpdate(EngineUpdate u) async {
    final row = await _rowForTask(u.taskId);
    if (row == null) return;
    if (u.status == null) {
      live.value = {
        ...live.value,
        row.id: LiveProgress(
          bytesPerSecond: u.bytesPerSecond,
          remaining: u.remaining,
        ),
      };
      await _update(
        row.id,
        DownloadsCompanion(
          progress: u.progress == null
              ? const Value.absent()
              : Value(u.progress!.clamp(0.0, 1.0)),
          totalBytes: u.totalBytes == null
              ? const Value.absent()
              : Value(u.totalBytes),
          // Progress means the transfer is running (e.g. after resume).
          status: row.status == DownloadStatus.waiting
              ? const Value(DownloadStatus.running)
              : const Value.absent(),
        ),
      );
      return;
    }
    if (u.status != EngineStatus.running) {
      live.value = {...live.value}..remove(row.id);
    }
    switch (u.status!) {
      case EngineStatus.complete:
        await _finish(row);
      case EngineStatus.waiting:
        await _setStatus(row, DownloadStatus.waiting);
      case EngineStatus.running:
        await _setStatus(row, DownloadStatus.running);
      case EngineStatus.paused:
        await _setStatus(row, DownloadStatus.paused);
      case EngineStatus.canceled:
        await _setStatus(row, DownloadStatus.canceled);
      case EngineStatus.failed:
        await _update(
          row.id,
          DownloadsCompanion(
            status: const Value(DownloadStatus.failed),
            error: Value(u.error ?? 'The download failed. Try again.'),
          ),
        );
    }
  }

  Future<void> _setStatus(DownloadRow row, DownloadStatus status) async {
    // A canceled row stays canceled even if a late update arrives.
    if (row.status == DownloadStatus.canceled ||
        row.status == DownloadStatus.complete) {
      return;
    }
    await _update(row.id, DownloadsCompanion(status: Value(status)));
  }

  /// Validates the file, moves it to shared storage and adds it to the
  /// library (and the Downloads playlist when enabled).
  Future<void> _finish(DownloadRow row) async {
    if (row.status == DownloadStatus.complete) return;
    final task = _taskFor(row);
    final file = await _engine.tempFile(task);
    final invalid = await DownloadRules.validateFile(file, row.kind);
    if (invalid != null) {
      if (await file.exists()) await file.delete();
      await _update(
        row.id,
        DownloadsCompanion(
          status: const Value(DownloadStatus.failed),
          error: Value(invalid),
        ),
      );
      return;
    }
    final saved = await _engine.moveToShared(task, row.kind);
    if (saved == null) {
      await _update(
        row.id,
        const DownloadsCompanion(
          status: Value(DownloadStatus.failed),
          error: Value(
            'The file could not be saved to your music or video '
            'folder.',
          ),
        ),
      );
      return;
    }
    await _update(
      row.id,
      DownloadsCompanion(
        status: const Value(DownloadStatus.complete),
        progress: const Value(1),
        savedPath: Value(saved),
        error: const Value(null),
      ),
    );
    unawaited(_addToLibrary((await _row(row.id))!));
  }

  Future<void> _addToLibrary(DownloadRow row) async {
    try {
      await _refreshLibrary(row.kind);
      if (!await _prefs.downloadAddToPlaylist()) return;
      final deadline = DateTime.now().add(libraryWait);
      LibraryItem? item;
      while ((item = await libraryItemFor(row)) == null &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await _refreshLibrary(row.kind);
      }
      if (item == null) return;
      final playlist = await _playlists.findOrCreate(downloadsPlaylist);
      await _playlists.addMedia(playlist, [item.id]);
    } on Exception catch (e) {
      debugPrint('[downloads] library update failed: $e');
    }
  }

  /// Completes downloads that finished while the app was closed.
  Future<void> _reconcile() async {
    final open =
        await (_db.select(_t)..where(
              (t) => t.status.isInValues([
                DownloadStatus.waiting,
                DownloadStatus.running,
              ]),
            ))
            .get();
    for (final row in open) {
      final status = await _engine.statusOf(row.taskId);
      if (status == EngineStatus.complete) {
        await _finish(row);
      } else if (status == EngineStatus.failed) {
        await _update(
          row.id,
          const DownloadsCompanion(
            status: Value(DownloadStatus.failed),
            error: Value('The download was interrupted. Retry it.'),
          ),
        );
      }
    }
  }

  /// HEAD request: content type, file name and the URL after redirects.
  static UrlProbe httpProbe(http.Client client) => (uri) async {
    final request = http.Request('HEAD', uri)..followRedirects = true;
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 15));
    await response.stream.drain<void>();
    final disposition = response.headers['content-disposition'];
    final name = disposition == null
        ? null
        : RegExp(
            r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''',
            caseSensitive: false,
          ).firstMatch(disposition)?.group(1);
    return UrlInfo(
      mimeType: response.statusCode < 400
          ? response.headers['content-type']
          : null,
      fileName: name == null ? null : Uri.decodeComponent(name),
      finalUrl: response.request?.url,
    );
  };
}
