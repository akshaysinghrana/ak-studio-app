import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../../shared/data/app_database.dart';
import '../../discover/application/online_providers.dart';
import '../../playback/domain/media_source.dart';
import '../application/download_manager.dart';
import '../domain/download_rules.dart';
import 'download_actions.dart';

/// Download queue and history (ADR 0004).
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(downloadsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            tooltip: 'Download settings',
            onPressed: () => context.push(Routes.downloadSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (_) =>
                ref.read(downloadManagerProvider).clearFinished(),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear finished from list'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDownloadLinkDialog(context, ref),
        icon: const Icon(Icons.add_link_rounded),
        label: const Text('Download from link'),
      ),
      body: switch (rows) {
        AsyncData(:final value) when value.isEmpty => const _Empty(),
        AsyncData(:final value) => _List(rows: value),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppTokens.spaceL),
    children: [
      const Icon(Icons.download_rounded, size: 56),
      const SizedBox(height: 16),
      Text(
        'No downloads yet',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Download songs from Discover where the artist allows it, or paste a '
        'direct link to an MP3 or MP4 you have the right to download. Files '
        'are saved to Music/AS Media and Movies/AS Media and appear in your '
        'library.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _List extends StatelessWidget {
  const _List({required this.rows});

  final List<DownloadRow> rows;

  @override
  Widget build(BuildContext context) {
    bool active(DownloadRow r) =>
        r.status == DownloadStatus.running ||
        r.status == DownloadStatus.waiting ||
        r.status == DownloadStatus.paused;
    final inProgress = rows.where(active).toList();
    final failed = rows
        .where((r) => r.status == DownloadStatus.failed)
        .toList();
    final done = rows
        .where(
          (r) =>
              r.status == DownloadStatus.complete ||
              r.status == DownloadStatus.canceled,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (inProgress.isNotEmpty) ...[
          SectionHeader('In progress (${inProgress.length})'),
          for (final r in inProgress) _DownloadTile(row: r),
        ],
        if (failed.isNotEmpty) ...[
          SectionHeader('Failed (${failed.length})'),
          for (final r in failed) _DownloadTile(row: r),
        ],
        if (done.isNotEmpty) ...[
          const SectionHeader('Finished'),
          for (final r in done) _DownloadTile(row: r),
        ],
      ],
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.row});

  final DownloadRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(downloadManagerProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Map<String, LiveProgress>>(
      valueListenable: manager.live,
      builder: (context, live, _) {
        final info = live[row.id];
        final status = _statusLine(row, info);
        final showBar =
            row.status == DownloadStatus.running ||
            row.status == DownloadStatus.waiting ||
            row.status == DownloadStatus.paused;
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 4),
          onTap: row.status == DownloadStatus.complete
              ? () => _play(context, ref)
              : null,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
            child: SizedBox.square(
              dimension: 48,
              child: GeneratedArtwork(seed: row.title, kind: row.kind),
            ),
          ),
          title: Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: row.status == DownloadStatus.failed
                      ? scheme.error
                      : null,
                ),
              ),
              if (showBar) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  // Indeterminate until the first progress arrives.
                  value: row.progress > 0 ? row.progress : null,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ],
          ),
          subtitleTextStyle: text.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [..._actions(context, ref)],
          ),
        );
      },
    );
  }

  String _statusLine(DownloadRow r, LiveProgress? info) {
    final source = switch (r.source) {
      'audius' => 'Audius',
      'jamendo' => 'Jamendo',
      _ => Uri.tryParse(r.url)?.host ?? 'Link',
    };
    final size = r.totalBytes == null ? null : _bytes(r.totalBytes!);
    return switch (r.status) {
      DownloadStatus.running => [
        '${(r.progress * 100).round()}%',
        ?size,
        if (info?.bytesPerSecond != null) '${_bytes(info!.bytesPerSecond!)}/s',
        if (info?.remaining != null) '${_eta(info!.remaining!)} left',
      ].join(' · '),
      DownloadStatus.waiting => 'Waiting · $source',
      DownloadStatus.paused => 'Paused at ${(r.progress * 100).round()}%',
      DownloadStatus.complete => [
        'Saved to ${r.kind == MediaKind.audio ? 'Music' : 'Movies'}/AS Media',
        ?size,
        source,
      ].join(' · '),
      DownloadStatus.failed => r.error ?? 'Failed',
      DownloadStatus.canceled => 'Canceled · $source',
    };
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final m = ref.read(downloadManagerProvider);
    IconButton btn(String tip, IconData icon, VoidCallback onPressed) =>
        IconButton(tooltip: tip, onPressed: onPressed, icon: Icon(icon));
    return switch (row.status) {
      DownloadStatus.running || DownloadStatus.waiting => [
        btn('Pause', Icons.pause_rounded, () => m.pause(row.id)),
        btn('Cancel', Icons.close_rounded, () => m.cancel(row.id)),
      ],
      DownloadStatus.paused => [
        btn('Resume', Icons.play_arrow_rounded, () => m.resume(row.id)),
        btn('Cancel', Icons.close_rounded, () => m.cancel(row.id)),
      ],
      DownloadStatus.failed || DownloadStatus.canceled => [
        btn('Retry', Icons.refresh_rounded, () => m.retry(row.id)),
        btn('Remove from list', Icons.delete_outline, () => m.remove(row.id)),
      ],
      DownloadStatus.complete => [
        btn(
          'Play',
          Icons.play_circle_outline_rounded,
          () => _play(context, ref),
        ),
        btn('Remove from list', Icons.delete_outline, () => m.remove(row.id)),
      ],
    };
  }

  /// Plays the saved file: as its library item when indexed (so progress
  /// and favourites work), else directly from its path.
  Future<void> _play(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final path = row.savedPath;
    if (path == null) return;
    final item = await ref.read(downloadManagerProvider).libraryItemFor(row);
    final MediaSource? media;
    if (item != null) {
      media = MediaSource(
        id: item.id,
        title: item.title,
        locator: item.locator,
        kind: item.kind,
        artist: item.artist,
        album: item.album,
      );
    } else if (await File(path).exists()) {
      media = MediaSource.fromFile(path: path, name: path.split('/').last);
    } else {
      media = null;
    }
    if (media == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('The file is no longer on this phone.')),
      );
      return;
    }
    await ref.read(coordinatorProvider).playNow([media]);
    router.push(Routes.player);
  }

  static String _bytes(num b) {
    if (b >= 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(1)} GB';
    if (b >= 1 << 20) return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
    if (b >= 1 << 10) return '${(b / (1 << 10)).toStringAsFixed(0)} KB';
    return '$b B';
  }

  static String _eta(Duration d) => d.inHours > 0
      ? '${d.inHours}h ${d.inMinutes.remainder(60)}m'
      : d.inMinutes > 0
      ? '${d.inMinutes}m ${d.inSeconds.remainder(60)}s'
      : '${d.inSeconds}s';
}

/// Asks for a direct MP3/MP4 link and starts the download.
Future<void> showDownloadLinkDialog(BuildContext context, WidgetRef ref) async {
  final url = TextEditingController();
  final title = TextEditingController();
  final result = await showDialog<(String, String)>(
    context: context,
    useRootNavigator: true,
    builder: (context) {
      String? error;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Download from link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: url,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Direct link to an MP3 or MP4',
                  hintText: 'https://…/song.mp3',
                  errorText: error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Only download files you have the right to save. YouTube '
                'links are not supported.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final problem = DownloadRules.validateUrl(url.text);
                if (problem != null) {
                  setState(() => error = problem);
                  return;
                }
                Navigator.pop(context, (url.text.trim(), title.text.trim()));
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );
    },
  );
  url.dispose();
  title.dispose();
  if (result == null || !context.mounted) return;
  await DownloadActions.url(
    context,
    ref,
    result.$1,
    title: result.$2.isEmpty ? null : result.$2,
  );
}
