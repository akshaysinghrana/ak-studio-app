import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/platform/media_store.dart';
import '../../library/data/media_library_repository.dart';
import '../../playback/domain/media_source.dart';

/// One-time move of files downloaded by older versions of the app. Those
/// builds kept finished downloads in app-private storage
/// (`<documents>/downloads`, including a per-job subfolder for extractor
/// jobs); current builds save straight into the public `Download/AS Media`
/// folder. This republishes any leftovers and re-points their library rows,
/// so the files survive and become visible to the gallery and other apps.
class LegacyDownloadMigration {
  LegacyDownloadMigration({required this.store, required this.library});

  final MediaStoreGateway store;
  final MediaLibraryRepository library;

  /// The app-private folder older builds saved downloads into.
  static Future<Directory> legacyDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'downloads'));
  }

  /// Publishes every media file found under the old private folder. Returns
  /// true when nothing is left to move (so the caller records the run as
  /// done); false when at least one file could not be published, leaving it
  /// in place for a later retry.
  Future<bool> run() async {
    final dir = await legacyDirectory();
    if (!await dir.exists()) return true;
    var complete = true;
    for (final file in await _mediaFiles(dir)) {
      if (!await _migrate(file)) complete = false;
    }
    if (complete) {
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
      } on FileSystemException {
        // An empty leftover folder is harmless.
      }
    }
    return complete;
  }

  /// Moves one file into the public folder and keeps the library in step.
  /// Returns false when it could not be published.
  Future<bool> _migrate(File file) async {
    final name = p.basename(file.path);
    final kind = _kindFor(name);
    if (kind == null) return true; // Not media we handle: leave it behind.
    final int size;
    try {
      size = await file.length();
    } on FileSystemException {
      return false;
    }
    final mimeType = _mimeType(kind, name);
    final published = await store.publishDownload(
      sourcePath: file.path,
      displayName: name,
      mimeType: mimeType,
    );
    if (published == null) return false;
    final relocated = await library.relocateDownload(
      oldLocator: file.path,
      newLocator: published,
      mimeType: mimeType,
      sizeBytes: size,
    );
    if (!relocated) {
      await library.registerDownload(
        locator: published,
        title: p.basenameWithoutExtension(name),
        displayName: name,
        kind: kind,
        mimeType: mimeType,
        sizeBytes: size,
      );
    }
    return true;
  }

  Future<List<File>> _mediaFiles(Directory dir) async {
    final files = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) files.add(entity);
    }
    return files;
  }

  /// Media kind for [name], or null for files the app cannot play (partial
  /// downloads, thumbnails, leftovers).
  MediaKind? _kindFor(String name) {
    final ext = p.extension(name).toLowerCase();
    if (const {'.mp4', '.m4v', '.mkv', '.webm', '.mov'}.contains(ext)) {
      return MediaKind.video;
    }
    if (const {
      '.mp3',
      '.m4a',
      '.aac',
      '.ogg',
      '.opus',
      '.wav',
      '.flac',
    }.contains(ext)) {
      return MediaKind.audio;
    }
    return null;
  }

  /// MIME type the file is published with, mirroring the download flow.
  String _mimeType(MediaKind kind, String name) {
    if (kind == MediaKind.video) return 'video/mp4';
    return switch (p.extension(name).toLowerCase()) {
      '.m4a' => 'audio/mp4',
      '.aac' => 'audio/aac',
      '.ogg' || '.opus' => 'audio/ogg',
      '.wav' => 'audio/wav',
      '.flac' => 'audio/flac',
      _ => 'audio/mpeg',
    };
  }
}
