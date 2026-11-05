import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/data/app_database.dart';
import '../../../downloads/presentation/download_actions.dart';
import '../../../library/presentation/widgets/media_tile.dart';
import '../../../playback/domain/media_source.dart';
import '../../application/online_providers.dart';
import '../../domain/catalog.dart';

/// Plays [tracks] from [index] onward through the app's player (ADR 0004).
Future<void> playCatalogTracks(
  BuildContext context,
  WidgetRef ref,
  List<CatalogTrack> tracks,
  int index,
) async {
  final router = GoRouter.of(context);
  await ref.read(coordinatorProvider).playNow([
    for (final t in tracks) t.toMediaSource(),
  ], startIndex: index);
  router.push(Routes.player);
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

class CatalogTrackTile extends ConsumerWidget {
  const CatalogTrackTile({
    super.key,
    required this.tracks,
    required this.index,
    this.rank,
  });

  final List<CatalogTrack> tracks;
  final int index;

  /// Chart position shown before the artwork.
  final int? rank;

  CatalogTrack get track => tracks[index];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final download = ref.watch(downloadsBySourceProvider).value?[track.key];
    final subtitle = [
      ?track.artist,
      if (track.duration != null) formatDuration(track.duration!),
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      onTap: () => playCatalogTracks(context, ref, tracks, index),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank != null)
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: text.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
            child: SizedBox.square(
              dimension: 52,
              child: ThumbnailImage(
                path: track.artworkUrl,
                seed: track.title,
                kind: MediaKind.audio,
              ),
            ),
          ),
        ],
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (track.canDownload) _DownloadButton(track: track, row: download),
          _TrackMenu(track: track),
        ],
      ),
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  const _DownloadButton({required this.track, required this.row});

  final CatalogTrack track;
  final DownloadRow? row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final status = row?.status;
    if (status == DownloadStatus.complete) {
      return IconButton(
        tooltip: 'Downloaded',
        onPressed: () => context.push(Routes.downloads),
        icon: Icon(Icons.download_done_rounded, color: scheme.primary),
      );
    }
    if (status == DownloadStatus.running ||
        status == DownloadStatus.waiting ||
        status == DownloadStatus.paused) {
      final progress = row!.progress;
      return IconButton(
        tooltip: status == DownloadStatus.paused
            ? 'Download paused'
            : 'Downloading ${(progress * 100).round()}%',
        onPressed: () => context.push(Routes.downloads),
        icon: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    return IconButton(
      tooltip: 'Download',
      onPressed: () => DownloadActions.track(context, ref, track),
      icon: const Icon(Icons.download_rounded),
    );
  }
}

enum _Action { playNext, addToQueue, download, artist }

class _TrackMenu extends ConsumerWidget {
  const _TrackMenu({required this.track});

  final CatalogTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<_Action>(
    tooltip: 'More options for ${track.title}',
    onSelected: (action) async {
      final coordinator = ref.read(coordinatorProvider);
      final messenger = ScaffoldMessenger.of(context);
      switch (action) {
        case _Action.playNext:
          await coordinator.playNextInQueue(track.toMediaSource());
          messenger.showSnackBar(const SnackBar(content: Text('Plays next')));
        case _Action.addToQueue:
          await coordinator.addToQueue(track.toMediaSource());
          messenger.showSnackBar(
            const SnackBar(content: Text('Added to queue')),
          );
        case _Action.download:
          if (context.mounted) {
            await DownloadActions.track(context, ref, track);
          }
        case _Action.artist:
          if (context.mounted) {
            context.push(
              Routes.catalogArtist(track.source, track.artistId!),
              extra: track.artist,
            );
          }
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(value: _Action.playNext, child: Text('Play next')),
      const PopupMenuItem(
        value: _Action.addToQueue,
        child: Text('Add to queue'),
      ),
      if (track.canDownload)
        const PopupMenuItem(value: _Action.download, child: Text('Download'))
      else
        const PopupMenuItem(
          enabled: false,
          child: Text('Download not allowed by the artist'),
        ),
      if (track.artistId != null)
        PopupMenuItem(
          value: _Action.artist,
          child: Text('Go to ${track.artist ?? 'artist'}'),
        ),
    ],
  );
}
