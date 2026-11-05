import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../youtube/presentation/youtube_section.dart';
import '../application/online_providers.dart';
import '../domain/catalog.dart';
import 'widgets/catalog_cards.dart';
import 'widgets/catalog_track_tile.dart';

enum _Section { music, youtube }

/// Online discovery (ADR 0004): music catalogues that allow streaming and
/// YouTube in its official player. The local library is unaffected.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  var _section = _Section.music;
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeDownloadCountProvider).value ?? 0;
    final music = _section == _Section.music;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: active > 0
                ? 'Downloads, $active in progress'
                : 'Downloads',
            onPressed: () => context.push(Routes.downloads),
            icon: Badge(
              isLabelVisible: active > 0,
              label: Text('$active'),
              child: const Icon(Icons.download_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Online sources',
            onPressed: () => context.push(Routes.onlineSources),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<_Section>(
              segments: const [
                ButtonSegment(
                  value: _Section.music,
                  icon: Icon(Icons.graphic_eq_rounded),
                  label: Text('Music'),
                ),
                ButtonSegment(
                  value: _Section.youtube,
                  icon: Icon(Icons.smart_display_outlined),
                  label: Text('YouTube'),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (s) => setState(() => _section = s.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _search,
              hintText: music
                  ? 'Songs, artists or playlists'
                  : 'Search YouTube',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_search.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _search.clear();
                      _submit('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
              onChanged: (v) {
                setState(() {});
                _onChanged(v);
              },
              onSubmitted: _submit,
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: music
                ? _MusicSection(query: _query)
                : YouTubeSection(query: _query),
          ),
        ],
      ),
    );
  }
}

class _MusicSection extends ConsumerStatefulWidget {
  const _MusicSection({required this.query});

  final String query;

  @override
  ConsumerState<_MusicSection> createState() => _MusicSectionState();
}

class _MusicSectionState extends ConsumerState<_MusicSection> {
  String? _genre;

  static const _genres = [
    'Electronic',
    'Hip-Hop/Rap',
    'Lo-Fi',
    'Pop',
    'Rock',
    'R&B/Soul',
    'Alternative',
    'Ambient',
    'Jazz',
    'Acoustic',
    'Latin',
    'Classical',
  ];

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(selectedCatalogProvider);
    final jamendoReady = ref.watch(jamendoCatalogProvider) != null;
    final sources = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final s in CatalogSource.values)
            ChoiceChip(
              label: Text(
                s == CatalogSource.jamendo && !jamendoReady
                    ? '${s.label} · set up'
                    : s.label,
              ),
              selected: source == s,
              onSelected: (_) {
                if (s == CatalogSource.jamendo && !jamendoReady) {
                  context.push(Routes.onlineSources);
                  return;
                }
                ref.read(selectedCatalogProvider.notifier).select(s);
              },
            ),
        ],
      ),
    );
    if (widget.query.isNotEmpty) {
      return Column(
        children: [
          sources,
          Expanded(
            child: _SearchResults(source: source, query: widget.query),
          ),
        ],
      );
    }
    final trending = ref.watch(trendingTracksProvider((source, _genre)));
    final playlists = ref.watch(featuredPlaylistsProvider(source));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(trendingTracksProvider((source, _genre)));
        ref.invalidate(featuredPlaylistsProvider(source));
        await ref.read(trendingTracksProvider((source, _genre)).future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: sources),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final g in [null, ..._genres])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(g ?? 'All genres'),
                        selected: _genre == g,
                        onSelected: (_) => setState(() => _genre = g),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_genre == null && (playlists.value?.isNotEmpty ?? false)) ...[
            const SliverToBoxAdapter(
              child: SectionHeader('Featured playlists'),
            ),
            SliverToBoxAdapter(
              child: PlaylistCarousel(playlists: playlists.value!),
            ),
          ],
          SliverToBoxAdapter(
            child: SectionHeader(
              _genre == null ? 'Trending this week' : 'Trending in $_genre',
            ),
          ),
          ...switch (trending) {
            AsyncData(:final value) when value.isEmpty => [
              const SliverToBoxAdapter(
                child: OnlineMessage(
                  icon: Icons.music_off_rounded,
                  message: 'Nothing trending here right now.',
                ),
              ),
            ],
            AsyncData(:final value) => [
              SliverList.builder(
                itemCount: value.length,
                itemBuilder: (context, i) =>
                    CatalogTrackTile(tracks: value, index: i, rank: i + 1),
              ),
            ],
            AsyncError(:final error) => [
              SliverToBoxAdapter(
                child: OnlineMessage(
                  icon: Icons.wifi_off_rounded,
                  message: '$error',
                  onRetry: () =>
                      ref.invalidate(trendingTracksProvider((source, _genre))),
                ),
              ),
            ],
            _ => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          },
          SliverToBoxAdapter(child: SourceCredit(source: source)),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.source, required this.query});

  final CatalogSource source;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(catalogSearchProvider((source, query)));
    return switch (results) {
      AsyncData(:final value) when value.isEmpty => OnlineMessage(
        icon: Icons.search_off_rounded,
        message: 'No results for "$query" on ${source.label}.',
      ),
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (value.artists.isNotEmpty) ...[
            const SectionHeader('Artists'),
            ArtistCarousel(artists: value.artists),
          ],
          if (value.playlists.isNotEmpty) ...[
            const SectionHeader('Playlists and albums'),
            PlaylistCarousel(playlists: value.playlists),
          ],
          if (value.tracks.isNotEmpty) ...[
            const SectionHeader('Songs'),
            for (var i = 0; i < value.tracks.length; i++)
              CatalogTrackTile(tracks: value.tracks, index: i),
          ],
          SourceCredit(source: source),
        ],
      ),
      AsyncError(:final error) => OnlineMessage(
        icon: Icons.wifi_off_rounded,
        message: '$error',
        onRetry: () => ref.invalidate(catalogSearchProvider((source, query))),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// A centred icon and message, with an optional retry button.
class OnlineMessage extends StatelessWidget {
  const OnlineMessage({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.action,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spaceL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
          ?action,
        ],
      ),
    );
  }
}

/// Attribution for catalogue content.
class SourceCredit extends StatelessWidget {
  const SourceCredit({super.key, required this.source});

  final CatalogSource source;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Text(
      switch (source) {
        CatalogSource.audius =>
          'Music from Audius. Downloads appear only where the artist allows '
              'them.',
        CatalogSource.jamendo =>
          'Music from Jamendo under Creative Commons licences.',
      },
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
