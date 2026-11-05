import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../library/application/library_providers.dart';
import '../../playback/domain/play_queue.dart';
import '../../playback/domain/media_source.dart';
import '../../library/presentation/widgets/media_tile.dart';
import '../../playlists/application/playlist_providers.dart';
import '../../playback/application/playback_coordinator.dart';
import 'widgets/player_sheets.dart';
import 'widgets/queue_sheet.dart';
import 'widgets/seek_bar.dart';
import 'widgets/transport_controls.dart';

/// Music Now Playing (spec 6.1): blurred artwork backdrop, large artwork
/// (cover art or generated gradient art), tag metadata only when present,
/// seek bar, transport with ±10 s, repeat/favourite/shuffle, speed and sleep.
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
        final scheme = Theme.of(context).colorScheme;
        final subtitle = [media?.artist, media?.album].nonNulls.join(' · ');
        final art = media == null
            ? null
            : media.artworkUrl ??
                  ref.watch(thumbnailProvider(media.locator)).value;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            ),
            title: Text('Now playing', style: text.titleMedium),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Queue',
                onPressed: () => showQueueSheet(context),
                icon: const Icon(Icons.queue_music_rounded),
              ),
            ],
          ),
          body: media == null
              ? const Center(child: Text('Nothing is playing.'))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blurred artwork wash behind everything.
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Opacity(
                        opacity: 0.55,
                        child: ThumbnailImage(
                          path: art,
                          seed: media.title,
                          kind: media.kind,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.surface.withValues(alpha: 0.35),
                            scheme.surfaceContainerLowest.withValues(
                              alpha: 0.95,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = (constraints.maxWidth - 64).clamp(
                            140.0,
                            380.0,
                          );
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                            children: [
                              Center(
                                child: _Artwork(
                                  path: art,
                                  seed: media.title,
                                  size: size,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                media.title,
                                style: text.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    subtitle,
                                    style: text.titleSmall?.copyWith(
                                      color: scheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 16),
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
                              const SizedBox(height: 8),
                              _ModeRow(
                                mediaId: media.id,
                                canFavorite: !media.isOnline,
                              ),
                              const SizedBox(height: 8),
                              _ExtrasRow(coordinator: coordinator),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.path, required this.seed, required this.size});

  final String? path;
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: path == null ? 'No artwork' : 'Artwork',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusL),
          child: ThumbnailImage(path: path, seed: seed, kind: MediaKind.audio),
        ),
      ),
    );
  }
}

/// Repeat, favourite and shuffle (spec 6.1). The repeat button cycles
/// off → all → one and states the mode in its label, not colour alone.
class _ModeRow extends ConsumerWidget {
  const _ModeRow({required this.mediaId, required this.canFavorite});

  final String mediaId;

  /// Streamed catalogue tracks are not library items; download them first.
  final bool canFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    final queue = coordinator.playQueue.value;
    final favorite = ref.watch(isFavoriteProvider(mediaId)).value ?? false;
    final (icon, label, next) = switch (queue.repeat) {
      QueueRepeat.off => (Icons.repeat, 'Repeat off', QueueRepeat.all),
      QueueRepeat.all => (Icons.repeat_on, 'Repeat all', QueueRepeat.one),
      QueueRepeat.one => (Icons.repeat_one_on, 'Repeat one', QueueRepeat.off),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: '$label. Tap to change.',
          onPressed: () => coordinator.setRepeat(next),
          icon: Icon(icon),
        ),
        if (canFavorite)
          IconButton(
            tooltip: favorite ? 'Remove from favourites' : 'Add to favourites',
            isSelected: favorite,
            onPressed: () =>
                ref.read(playlistRepositoryProvider).toggleFavorite(mediaId),
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
          ),
        IconButton(
          tooltip: queue.shuffled ? 'Shuffle on' : 'Shuffle off',
          isSelected: queue.shuffled,
          onPressed: () => coordinator.setShuffle(!queue.shuffled),
          icon: const Icon(Icons.shuffle),
          selectedIcon: const Icon(Icons.shuffle_on),
        ),
      ],
    );
  }
}

/// Speed and sleep timer, with a live countdown (spec 6.3).
class _ExtrasRow extends StatefulWidget {
  const _ExtrasRow({required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  State<_ExtrasRow> createState() => _ExtrasRowState();
}

class _ExtrasRowState extends State<_ExtrasRow> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.coordinator.sleepTimer.value?.endsAt != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coordinator;
    return ListenableBuilder(
      listenable: Listenable.merge([c.speed, c.sleepTimer]),
      builder: (context, _) {
        final timer = c.sleepTimer.value;
        final left = timer?.remaining(DateTime.now());
        final timerLabel = timer == null
            ? 'Sleep timer'
            : timer.endOfItem
            ? 'Ends after this'
            : '${left!.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.speed),
              label: Text(speedLabel(c.speed.value)),
              tooltip: 'Playback speed',
              onPressed: () => showSpeedSheet(context, c),
            ),
            ActionChip(
              avatar: Icon(
                timer == null ? Icons.bedtime_outlined : Icons.bedtime,
              ),
              label: Text(timerLabel),
              tooltip: 'Sleep timer',
              onPressed: () => showSleepTimerSheet(context, c),
            ),
          ],
        );
      },
    );
  }
}
