import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../library/application/library_providers.dart';
import '../../playback/domain/play_queue.dart';
import 'widgets/queue_sheet.dart';
import 'widgets/seek_bar.dart';
import 'widgets/transport_controls.dart';

/// Music Now Playing (spec 6.1): artwork or a neutral placeholder, tag
/// metadata only when present, seek bar and transport with ±10 s.
class MusicPlayerScreen extends ConsumerWidget {
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    return ValueListenableBuilder<PlayQueue>(
      valueListenable: coordinator.playQueue,
      builder: (context, queue, _) {
        final media = queue.current?.media;
        final text = Theme.of(context).textTheme;
        final subtitle = [media?.artist, media?.album].nonNulls.join(' · ');
        return Scaffold(
          appBar: AppBar(
            title: const Text('Now playing'),
            actions: [
              IconButton(
                tooltip: 'Queue',
                onPressed: () => showQueueSheet(context, coordinator),
                icon: const Icon(Icons.queue_music),
              ),
            ],
          ),
          body: media == null
              ? const Center(child: Text('Nothing is playing.'))
              : SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final art = (constraints.maxWidth - 64).clamp(
                        120.0,
                        360.0,
                      );
                      return ListView(
                        padding: const EdgeInsets.all(AppTokens.spaceL),
                        children: [
                          Center(
                            child: _Artwork(locator: media.locator, size: art),
                          ),
                          const SizedBox(height: AppTokens.spaceL),
                          Text(
                            media.title,
                            style: text.headlineSmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: text.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: AppTokens.spaceM),
                          ValueListenableBuilder<VideoPlayerController?>(
                            valueListenable: coordinator.controller,
                            builder: (context, controller, _) =>
                                controller == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SeekBar(
                                    controller: controller,
                                    onSeek: coordinator.seek,
                                  ),
                          ),
                          PlaybackErrorBanner(coordinator: coordinator),
                          TransportControls(
                            coordinator: coordinator,
                            showSeekBar: false,
                          ),
                        ],
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _Artwork extends ConsumerWidget {
  const _Artwork({required this.locator, required this.size});

  final String locator;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final path = ref.watch(thumbnailProvider(locator)).value;
    final placeholder = Icon(
      Icons.music_note,
      size: size / 3,
      color: scheme.onSurfaceVariant,
    );
    return Semantics(
      label: path == null ? 'No artwork' : 'Artwork',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusM),
        child: SizedBox.square(
          dimension: size,
          child: ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: path == null
                ? placeholder
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
        ),
      ),
    );
  }
}
