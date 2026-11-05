import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bd;

import '../../playback/domain/media_source.dart';

enum EngineStatus { waiting, running, paused, complete, failed, canceled }

class EngineTask {
  const EngineTask({
    required this.taskId,
    required this.url,
    required this.fileName,
    required this.displayName,
  });

  final String taskId;
  final String url;
  final String fileName;
  final String displayName;
}

class EngineUpdate {
  const EngineUpdate({
    required this.taskId,
    this.status,
    this.progress,
    this.bytesPerSecond,
    this.remaining,
    this.totalBytes,
    this.error,
  });

  final String taskId;

  /// Set for status changes; null for progress-only updates.
  final EngineStatus? status;
  final double? progress;
  final double? bytesPerSecond;
  final Duration? remaining;
  final int? totalBytes;
  final String? error;
}

/// The transfer layer under [DownloadManager] (a seam for tests).
abstract interface class DownloadEngine {
  Stream<EngineUpdate> get updates;

  Future<void> start({required int concurrency, required bool wifiOnly});

  Future<void> setConcurrency(int concurrency);

  Future<void> setWifiOnly(bool wifiOnly);

  /// Asks for notification permission (download progress). Returns false if
  /// denied; downloads still run.
  Future<bool> ensureNotificationPermission();

  Future<bool> enqueue(EngineTask task);

  Future<bool> pause(String taskId);

  Future<bool> resume(String taskId);

  Future<void> cancel(String taskId);

  /// Last known status from the engine's own records, for reconciling after
  /// the app was closed; null if unknown.
  Future<EngineStatus?> statusOf(String taskId);

  /// The finished file in app storage.
  Future<File> tempFile(EngineTask task);

  /// Moves a finished file to `Music/AS Media` or `Movies/AS Media`;
  /// returns the shared path or null on failure.
  Future<String?> moveToShared(EngineTask task, MediaKind kind);
}

/// [DownloadEngine] on `background_downloader` (WorkManager, or UIDT jobs on
/// Android 14+): survives the app closing, resumes with HTTP Range, retries,
/// shows progress notifications.
class BackgroundDownloaderEngine implements DownloadEngine {
  BackgroundDownloaderEngine([bd.FileDownloader? downloader])
    : _d = downloader ?? bd.FileDownloader();

  final bd.FileDownloader _d;
  static const _directory = 'downloads';
  static const _sharedFolder = 'AS Media';

  final _updates = StreamController<EngineUpdate>.broadcast();
  StreamSubscription<bd.TaskUpdate>? _sub;

  @override
  Stream<EngineUpdate> get updates => _updates.stream;

  bd.DownloadTask _task(EngineTask t) => bd.DownloadTask(
    taskId: t.taskId,
    url: t.url,
    filename: t.fileName,
    directory: _directory,
    baseDirectory: bd.BaseDirectory.applicationSupport,
    displayName: t.displayName,
    updates: bd.Updates.statusAndProgress,
    allowPause: true,
    retries: 3,
    // User-initiated: UIDT on Android 14+, so long downloads are not cut off.
    priority: 0,
  );

  @override
  Future<void> start({required int concurrency, required bool wifiOnly}) async {
    _sub ??= _d.updates.listen(_onUpdate);
    _d.configureNotification(
      running: const bd.TaskNotification('Downloading', '{displayName}'),
      paused: const bd.TaskNotification('Download paused', '{displayName}'),
      complete: const bd.TaskNotification('Download complete', '{displayName}'),
      error: const bd.TaskNotification('Download failed', '{displayName}'),
      progressBar: true,
    );
    await setConcurrency(concurrency);
    await setWifiOnly(wifiOnly);
    await _d.start();
  }

  @override
  Future<void> setConcurrency(int concurrency) async {
    await _d.configure(
      globalConfig: [(bd.Config.holdingQueue, (concurrency, null, null))],
    );
  }

  @override
  Future<void> setWifiOnly(bool wifiOnly) async {
    await _d.requireWiFi(
      wifiOnly ? bd.RequireWiFi.forAllTasks : bd.RequireWiFi.forNoTasks,
    );
  }

  @override
  Future<bool> ensureNotificationPermission() async {
    final type = bd.PermissionType.notifications;
    var status = await _d.permissions.status(type);
    if (status != bd.PermissionStatus.granted) {
      status = await _d.permissions.request(type);
    }
    return status == bd.PermissionStatus.granted;
  }

  @override
  Future<bool> enqueue(EngineTask task) => _d.enqueue(_task(task));

  Future<bd.DownloadTask?> _find(String taskId) async {
    final task =
        await _d.taskForId(taskId) ??
        (await _d.database.recordForId(taskId))?.task;
    return task is bd.DownloadTask ? task : null;
  }

  @override
  Future<bool> pause(String taskId) async {
    final task = await _find(taskId);
    return task != null && await _d.pause(task);
  }

  @override
  Future<bool> resume(String taskId) async {
    final task = await _find(taskId);
    return task != null && await _d.resume(task);
  }

  @override
  Future<void> cancel(String taskId) async {
    await _d.cancelTaskWithId(taskId);
  }

  @override
  Future<EngineStatus?> statusOf(String taskId) async {
    final record = await _d.database.recordForId(taskId);
    return record == null ? null : _status(record.status);
  }

  static EngineStatus _status(bd.TaskStatus s) => switch (s) {
    bd.TaskStatus.enqueued ||
    bd.TaskStatus.waitingToRetry => EngineStatus.waiting,
    bd.TaskStatus.running => EngineStatus.running,
    bd.TaskStatus.paused => EngineStatus.paused,
    bd.TaskStatus.complete => EngineStatus.complete,
    bd.TaskStatus.canceled => EngineStatus.canceled,
    bd.TaskStatus.failed || bd.TaskStatus.notFound => EngineStatus.failed,
  };

  @override
  Future<File> tempFile(EngineTask task) async =>
      File(await _task(task).filePath());

  @override
  Future<String?> moveToShared(EngineTask task, MediaKind kind) =>
      _d.moveToSharedStorage(
        _task(task),
        kind == MediaKind.audio
            ? bd.SharedStorage.audio
            : bd.SharedStorage.video,
        directory: _sharedFolder,
        mimeType: kind == MediaKind.audio ? 'audio/mpeg' : 'video/mp4',
      );

  void _onUpdate(bd.TaskUpdate update) {
    switch (update) {
      case bd.TaskStatusUpdate():
        _updates.add(
          EngineUpdate(
            taskId: update.task.taskId,
            status: _status(update.status),
            error: switch (update.status) {
              bd.TaskStatus.notFound =>
                'The file was not found at that link (404).',
              bd.TaskStatus.failed => _describe(update.exception),
              _ => null,
            },
          ),
        );
      case bd.TaskProgressUpdate():
        // Negative progress values are status signals, not fractions.
        if (update.progress < 0) return;
        _updates.add(
          EngineUpdate(
            taskId: update.task.taskId,
            progress: update.progress,
            bytesPerSecond: update.hasNetworkSpeed
                ? update.networkSpeed * 1000 * 1000
                : null,
            remaining: update.hasTimeRemaining ? update.timeRemaining : null,
            totalBytes: update.hasExpectedFileSize
                ? update.expectedFileSize
                : null,
          ),
        );
    }
  }

  static String _describe(bd.TaskException? e) => switch (e) {
    bd.TaskHttpException(:final httpResponseCode) =>
      httpResponseCode == 403 || httpResponseCode == 401
          ? 'The server refused the download ($httpResponseCode).'
          : 'The server returned an error ($httpResponseCode).',
    bd.TaskConnectionException() =>
      'The connection was lost. Retry when you are online.',
    bd.TaskFileSystemException() =>
      'Not enough storage space, or the file '
          'could not be written.',
    _ => 'The download failed. Try again.',
  };
}
