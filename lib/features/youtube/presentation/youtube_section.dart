import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../discover/application/online_providers.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../discover/presentation/widgets/catalog_track_tile.dart';
import '../data/youtube_api.dart';
import 'youtube_player_screen.dart';

/// YouTube search and the music chart, played in the official embedded
/// player only (ADR 0004).
class YouTubeSection extends ConsumerWidget {
  const YouTubeSection({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(youtubeApiKeyProvider);
    if (key.isLoading) return const Center(child: CircularProgressIndicator());
    if (key.value == null) return const _NotConfigured();
    final provider = query.isEmpty
        ? youtubePopularProvider
        : youtubeSearchProvider(query);
    final videos = ref.watch(provider);
    return switch (videos) {
      AsyncData(:final value) when value.isEmpty => OnlineMessage(
        icon: Icons.search_off_rounded,
        message: query.isEmpty
            ? 'No popular music videos for your region.'
            : 'No YouTube results for "$query".',
      ),
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          await ref.read(provider.future);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SectionHeader(
              query.isEmpty ? 'Popular music videos' : 'Results from YouTube',
            ),
            for (var i = 0; i < value.length; i++)
              YouTubeVideoCard(videos: value, index: i),
          ],
        ),
      ),
      AsyncError(:final error) => OnlineMessage(
        icon: Icons.error_outline_rounded,
        message: '$error',
        onRetry: () => ref.invalidate(provider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppTokens.spaceL),
    children: [
      const Icon(Icons.smart_display_outlined, size: 56),
      const SizedBox(height: 16),
      Text(
        'YouTube is not set up yet',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Searching YouTube needs your own YouTube Data API key (free from '
        'Google Cloud Console). Videos play in YouTube\'s official player; '
        'they cannot be downloaded or played in the background.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      Center(
        child: GradientButton(
          label: 'Add API key',
          icon: Icons.key_rounded,
          onPressed: () => context.push(Routes.onlineSources),
        ),
      ),
    ],
  );
}

class YouTubeVideoCard extends StatelessWidget {
  const YouTubeVideoCard({
    super.key,
    required this.videos,
    required this.index,
    this.compact = false,
    this.onTap,
  });

  final List<YouTubeVideo> videos;
  final int index;

  /// Row layout for the "Up next" list.
  final bool compact;
  final VoidCallback? onTap;

  YouTubeVideo get video => videos[index];

  void _open(BuildContext context) => context.push(
    Routes.youtubePlayer,
    extra: YouTubePlayerArgs(videos: videos, index: index),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final meta = [
      video.channel,
      if (video.viewCount != null) '${compactCount(video.viewCount!)} views',
      if (video.publishedAt != null) timeAgo(video.publishedAt!),
    ].join(' · ');
    final thumb = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          video.thumbnailUrl == null
              ? ColoredBox(color: scheme.surfaceContainerHigh)
              : Image.network(
                  video.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: scheme.surfaceContainerHigh),
                ),
          if (video.duration != null)
            Positioned(
              right: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    formatDuration(video.duration!),
                    style: text.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (compact) {
      return InkWell(
        onTap: onTap ?? () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusS),
                  child: thumb,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onTap ?? () => _open(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusM),
              child: thumb,
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String compactCount(int n) {
  if (n >= 1000000000) return '${(n / 1e9).toStringAsFixed(1)}B';
  if (n >= 1000000) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1e3).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
  return '$n';
}

String timeAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inDays >= 365) return '${d.inDays ~/ 365}y ago';
  if (d.inDays >= 30) return '${d.inDays ~/ 30}mo ago';
  if (d.inDays >= 1) return '${d.inDays}d ago';
  if (d.inHours >= 1) return '${d.inHours}h ago';
  return '${d.inMinutes.clamp(1, 59)}m ago';
}
