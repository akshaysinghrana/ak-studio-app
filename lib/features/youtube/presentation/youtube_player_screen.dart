import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../app/providers.dart';
import '../../../app/theme/brand_widgets.dart';
import '../data/youtube_api.dart';
import 'youtube_section.dart';

class YouTubePlayerArgs {
  const YouTubePlayerArgs({required this.videos, required this.index});

  final List<YouTubeVideo> videos;
  final int index;
}

/// YouTube's official embedded player (ADR 0004). It is separate from the
/// app's player: opening it pauses local playback, it pauses whenever the app
/// leaves the foreground, and nothing is downloaded.
class YouTubePlayerScreen extends ConsumerStatefulWidget {
  const YouTubePlayerScreen({super.key, required this.args});

  final YouTubePlayerArgs args;

  @override
  ConsumerState<YouTubePlayerScreen> createState() =>
      _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends ConsumerState<YouTubePlayerScreen> {
  late final YoutubePlayerController _controller;
  late final AppLifecycleListener _lifecycle;
  late int _index = widget.args.index;

  YouTubeVideo get _video => widget.args.videos[_index];

  @override
  void initState() {
    super.initState();
    // Never two audible engines at once.
    ref.read(coordinatorProvider).pause();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
    _controller.loadVideoById(videoId: _video.id);
    // YouTube's terms forbid background play through an API client.
    _lifecycle = AppLifecycleListener(
      onHide: _controller.pauseVideo,
      onPause: _controller.pauseVideo,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.close();
    super.dispose();
  }

  void _play(int index) {
    setState(() => _index = index);
    _controller.loadVideoById(videoId: _video.id);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final video = _video;
    final upNext = [
      for (var i = 0; i < widget.args.videos.length; i++)
        if (i != _index) i,
    ];
    final player = YoutubePlayer(controller: _controller);
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube'),
        actions: [
          IconButton(
            tooltip: 'Share link',
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                uri: Uri.https('www.youtube.com', '/watch', {'v': video.id}),
              ),
            ),
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          player,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(video.title, style: text.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              [
                video.channel,
                if (video.viewCount != null)
                  '${compactCount(video.viewCount!)} views',
                if (video.publishedAt != null) timeAgo(video.publishedAt!),
              ].join(' · '),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Plays in YouTube\'s player. YouTube videos can\'t be '
              'downloaded or kept playing in the background.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (upNext.isNotEmpty) ...[
            const SectionHeader('Up next'),
            for (final i in upNext)
              YouTubeVideoCard(
                videos: widget.args.videos,
                index: i,
                compact: true,
                onTap: () => _play(i),
              ),
          ],
        ],
      ),
    );
  }
}
