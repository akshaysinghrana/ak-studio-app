import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// A download progress tick from the on-device extractor, [progress] in 0..1.
class ExtractorProgress {
  const ExtractorProgress({required this.processId, required this.progress});

  final String processId;
  final double progress;
}

/// The on-device extractor (yt-dlp) could not read or fetch the link.
class ExtractorException implements Exception {
  const ExtractorException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The user cancelled an extractor download.
class ExtractorCancelled extends ExtractorException {
  const ExtractorCancelled() : super('Download cancelled.');
}

/// The user paused an extractor download; its partial files were kept.
class ExtractorPaused extends ExtractorException {
  const ExtractorPaused() : super('Paused.');
}

/// On-device yt-dlp (through the native `youtubedl-android` bridge). Lets the
/// app resolve and download from sites the plain HTTP resolver cannot reach
/// (YouTube, Facebook, Instagram, ...) with no external server and no
/// configuration.
abstract interface class YoutubeDlGateway {
  /// True once the native extractor initialised (its native libs are present).
  Future<bool> isAvailable();

  /// yt-dlp metadata for [url], as the decoded `--dump-json` object.
  Future<Map<String, dynamic>> info(String url);

  /// Downloads [url] into `destDir/jobId` and returns the produced file's
  /// path. [processId] identifies this run for [cancel], [pause] and progress
  /// events. [format] is a yt-dlp format selector; [audioOnly] extracts audio
  /// (m4a). With [resume] the job folder is kept so partial files continue.
  Future<String> download({
    required String url,
    required String destDir,
    required String processId,
    String? jobId,
    String format,
    bool audioOnly,
    bool resume,
  });

  Future<void> cancel(String processId);

  /// Stops the run but keeps its partial files; [download] then throws
  /// [ExtractorPaused].
  Future<void> pause(String processId);

  /// Progress for downloads started with [download].
  Stream<ExtractorProgress> get progress;
}

class MethodChannelYoutubeDl implements YoutubeDlGateway {
  MethodChannelYoutubeDl() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const _channel = MethodChannel(
    'com.akshayrana.video_music_app/youtube_dl',
  );

  final _progress = StreamController<ExtractorProgress>.broadcast();

  @override
  Stream<ExtractorProgress> get progress => _progress.stream;

  Future<dynamic> _onCall(MethodCall call) async {
    if (call.method != 'progress') return null;
    final args = call.arguments;
    if (args is! Map) return null;
    final id = args['processId'];
    final value = args['progress'];
    if (id is! String || value is! num) return null;
    _progress.add(
      ExtractorProgress(
        processId: id,
        progress: value.toDouble().clamp(0.0, 1.0),
      ),
    );
    return null;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> info(String url) async {
    final json = await _guard(
      () => _channel.invokeMethod<String>('info', {'url': url}),
    );
    if (json == null || json.isEmpty) {
      throw const ExtractorException('That link could not be read.');
    }
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const ExtractorException(
        'The extractor returned an unexpected reply.',
      );
    }
    return decoded;
  }

  @override
  Future<String> download({
    required String url,
    required String destDir,
    required String processId,
    String? jobId,
    String format = 'bv*+ba/b',
    bool audioOnly = false,
    bool resume = false,
  }) async {
    final path = await _guard(
      () => _channel.invokeMethod<String>('download', {
        'url': url,
        'destDir': destDir,
        'processId': processId,
        'jobId': jobId ?? processId,
        'format': format,
        'audioOnly': audioOnly,
        'resume': resume,
      }),
    );
    if (path == null || path.isEmpty) {
      throw const ExtractorException('The download produced no file.');
    }
    return path;
  }

  @override
  Future<void> cancel(String processId) async {
    try {
      await _channel.invokeMethod<void>('cancel', {'processId': processId});
    } on PlatformException {
      // Nothing to cancel.
    } on MissingPluginException {
      // Extractor unavailable.
    }
  }

  @override
  Future<void> pause(String processId) async {
    try {
      await _channel.invokeMethod<void>('pause', {'processId': processId});
    } on PlatformException {
      // Nothing running.
    } on MissingPluginException {
      // Extractor unavailable.
    }
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on MissingPluginException {
      throw const ExtractorException(
        'The on-device extractor is not available on this device.',
      );
    } on PlatformException catch (e) {
      final message = e.message?.trim();
      if (e.code == 'cancelled') throw const ExtractorCancelled();
      if (e.code == 'paused') throw const ExtractorPaused();
      throw ExtractorException(
        (message == null || message.isEmpty)
            ? 'The extractor could not handle that link.'
            : message,
      );
    }
  }
}
