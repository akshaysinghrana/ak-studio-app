import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../library/presentation/widgets/media_tile.dart';
import '../../../playback/domain/media_source.dart';
import '../../domain/catalog.dart';

class PlaylistCarousel extends StatelessWidget {
  const PlaylistCarousel({super.key, required this.playlists});

  final List<CatalogPlaylist> playlists;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = playlists[i];
          return SizedBox(
            width: 140,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTokens.radiusM),
              onTap: () => context.push(
                Routes.catalogPlaylist(p.source, p.id),
                extra: p.name,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.radiusM),
                    child: SizedBox.square(
                      dimension: 140,
                      child: ThumbnailImage(
                        path: p.artworkUrl,
                        seed: p.name,
                        kind: MediaKind.audio,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  Text(
                    [if (p.isAlbum) 'Album', ?p.owner].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ArtistCarousel extends StatelessWidget {
  const ArtistCarousel({super.key, required this.artists});

  final List<CatalogArtist> artists;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final a = artists[i];
          return SizedBox(
            width: 92,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTokens.radiusM),
              onTap: () => context.push(
                Routes.catalogArtist(a.source, a.id),
                extra: a.name,
              ),
              child: Column(
                children: [
                  ClipOval(
                    child: SizedBox.square(
                      dimension: 84,
                      child: ThumbnailImage(
                        path: a.imageUrl,
                        seed: a.name,
                        kind: MediaKind.audio,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
