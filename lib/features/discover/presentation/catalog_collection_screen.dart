import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/brand_widgets.dart';
import '../application/online_providers.dart';
import '../domain/catalog.dart';
import 'discover_screen.dart';
import 'widgets/catalog_track_tile.dart';

enum CatalogCollectionKind { artist, playlist }

/// An artist's tracks or a catalogue playlist/album.
class CatalogCollectionScreen extends ConsumerWidget {
  const CatalogCollectionScreen({
    super.key,
    required this.kind,
    required this.source,
    required this.id,
    this.title,
  });

  final CatalogCollectionKind kind;
  final CatalogSource source;
  final String id;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = kind == CatalogCollectionKind.artist
        ? artistTracksProvider((source, id))
        : catalogPlaylistTracksProvider((source, id));
    final tracks = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title ??
              (kind == CatalogCollectionKind.artist ? 'Artist' : 'Playlist'),
        ),
      ),
      body: switch (tracks) {
        AsyncData(:final value) when value.isEmpty => const OnlineMessage(
          icon: Icons.music_off_rounded,
          message: 'No playable tracks here.',
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: 'Play all',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () =>
                          playCatalogTracks(context, ref, value, 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => playCatalogTracks(
                        context,
                        ref,
                        [...value]..shuffle(),
                        0,
                      ),
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Shuffle'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${value.length} tracks · '
                '${value.where((t) => t.canDownload).length} downloadable',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (var i = 0; i < value.length; i++)
              CatalogTrackTile(tracks: value, index: i),
            SourceCredit(source: source),
          ],
        ),
        AsyncError(:final error) => OnlineMessage(
          icon: Icons.wifi_off_rounded,
          message: '$error',
          onRetry: () => ref.invalidate(provider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
