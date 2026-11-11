import 'download_variant.dart';

enum DownloadStatus {
  /// Fetching the link and working out what can be downloaded.
  resolving,

  /// Options are ready and the user must pick one.
  choosing,
  downloading,

  /// Stopped by the user; the partial file is kept so it can resume.
  paused,
  saving,
  done,
  failed,
}

/// One "paste a link" job and its progress. Immutable; the controller
/// replaces instances as state changes.
class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.status = DownloadStatus.resolving,
    this.variants = const [],
    this.selected,
    this.receivedBytes = 0,
    this.totalBytes,
    this.bytesPerSecond = 0,
    this.error,
    this.note,
    this.savedPath,
    this.savedItemId,
    this.transferNote,
  });

  final String id;
  final String url;
  final String title;
  final DownloadStatus status;
  final List<DownloadVariant> variants;
  final DownloadVariant? selected;
  final int receivedBytes;
  final int? totalBytes;
  final double bytesPerSecond;
  final String? error;

  /// Informational message, e.g. how a page's video was located.
  final String? note;

  /// Where the finished download now lives (a `content://` URI once saved to
  /// the public Downloads folder, else an app-private path).
  final String? savedPath;

  /// Library row id of the saved file, used by Info / Delete actions.
  final String? savedItemId;

  /// Shown under the progress bar while downloading, e.g. that the
  /// connection dropped and the download will continue by itself.
  final String? transferNote;

  double? get progress {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }

  bool get isActive =>
      status == DownloadStatus.resolving ||
      status == DownloadStatus.downloading ||
      status == DownloadStatus.saving;

  bool get canPause => status == DownloadStatus.downloading;

  static const _sentinel = Object();

  DownloadTask copyWith({
    DownloadStatus? status,
    List<DownloadVariant>? variants,
    Object? selected = _sentinel,
    int? receivedBytes,
    Object? totalBytes = _sentinel,
    double? bytesPerSecond,
    Object? error = _sentinel,
    Object? note = _sentinel,
    Object? savedPath = _sentinel,
    Object? savedItemId = _sentinel,
    Object? transferNote = _sentinel,
    String? title,
  }) => DownloadTask(
    id: id,
    url: url,
    title: title ?? this.title,
    status: status ?? this.status,
    variants: variants ?? this.variants,
    selected: identical(selected, _sentinel)
        ? this.selected
        : selected as DownloadVariant?,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    totalBytes: identical(totalBytes, _sentinel)
        ? this.totalBytes
        : totalBytes as int?,
    bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
    error: identical(error, _sentinel) ? this.error : error as String?,
    note: identical(note, _sentinel) ? this.note : note as String?,
    savedPath: identical(savedPath, _sentinel)
        ? this.savedPath
        : savedPath as String?,
    savedItemId: identical(savedItemId, _sentinel)
        ? this.savedItemId
        : savedItemId as String?,
    transferNote: identical(transferNote, _sentinel)
        ? this.transferNote
        : transferNote as String?,
  );
}
