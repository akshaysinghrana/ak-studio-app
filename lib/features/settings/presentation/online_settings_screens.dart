import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../discover/application/online_providers.dart';

/// YouTube API key and Jamendo client ID (ADR 0004). Stored on this device
/// only; never synced.
class OnlineSourcesScreen extends ConsumerWidget {
  const OnlineSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(preferencesProvider);
    final youtube = ref.watch(youtubeApiKeyProvider).value;
    final jamendo = ref.watch(jamendoClientIdProvider).value;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Online sources')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SourceCard(
            icon: Icons.graphic_eq_rounded,
            title: 'Audius',
            status: 'Ready, no setup needed',
            ready: true,
            body:
                'Independent artists. Streams in the app with background '
                'and lock-screen controls. Download appears only on tracks '
                'whose artist allows it.',
          ),
          const SizedBox(height: 12),
          _SourceCard(
            icon: Icons.smart_display_outlined,
            title: 'YouTube',
            status: youtube == null ? 'Not set up' : 'Key saved',
            ready: youtube != null,
            body:
                'Search and the music chart use the YouTube Data API v3. '
                'Videos play in YouTube\'s official player only. They cannot '
                'be downloaded or played in the background.',
            steps: const [
              'Open console.cloud.google.com and create a project.',
              'Enable "YouTube Data API v3".',
              'Create an API key. Restrict it to Android apps with package '
                  'com.akshayrana.video_music_app and this app\'s SHA-1.',
              'Paste the key below.',
            ],
            field: _KeyField(
              label: 'YouTube Data API key',
              initial: youtube,
              onSave: prefs.setYoutubeApiKey,
            ),
          ),
          const SizedBox(height: 12),
          _SourceCard(
            icon: Icons.library_music_outlined,
            title: 'Jamendo',
            status: jamendo == null
                ? 'Not set up (optional)'
                : 'Client ID saved',
            ready: jamendo != null,
            body:
                'Creative Commons music. Most tracks can be downloaded for '
                'free.',
            steps: const [
              'Create a free account at devportal.jamendo.com.',
              'Register an application to get a client ID.',
              'Paste the client ID below.',
            ],
            field: _KeyField(
              label: 'Jamendo client ID',
              initial: jamendo,
              onSave: prefs.setJamendoClientId,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keys stay on this phone and are never synced or uploaded. '
            'Searches are sent to the service you search.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.ready,
    required this.body,
    this.steps = const [],
    this.field,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool ready;
  final String body;
  final List<String> steps;
  final Widget? field;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, size: 38),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: text.titleMedium)),
              Chip(
                avatar: Icon(
                  ready ? Icons.check_circle_rounded : Icons.info_outline,
                  size: 16,
                  color: ready ? scheme.primary : scheme.onSurfaceVariant,
                ),
                label: Text(status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final (i, s) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${i + 1}. $s',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          if (field != null) ...[const SizedBox(height: 12), field!],
        ],
      ),
    );
  }
}

class _KeyField extends StatefulWidget {
  const _KeyField({
    required this.label,
    required this.initial,
    required this.onSave,
  });

  final String label;
  final String? initial;
  final Future<void> Function(String value) onSave;

  @override
  State<_KeyField> createState() => _KeyFieldState();
}

class _KeyFieldState extends State<_KeyField> {
  late final _controller = TextEditingController(text: widget.initial ?? '');
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.onSave(_controller.text);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _controller.text.trim().isEmpty
              ? '${widget.label} removed'
              : '${widget.label} saved',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: _controller,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Show' : 'Hide',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
          onSubmitted: (_) => _save(),
        ),
      ),
      const SizedBox(width: 8),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

/// Download preferences (ADR 0004).
class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(preferencesProvider);
    final manager = ref.read(downloadManagerProvider);
    final wifiOnly = ref.watch(_wifiOnlyProvider).value ?? false;
    final concurrency = ref.watch(_concurrencyProvider).value ?? 2;
    final playlist = ref.watch(_addToPlaylistProvider).value ?? true;
    final quality = ref.watch(jamendoQualityProvider).value ?? 'mp32';
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Download settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: IconBadge(
                    icon: Icons.wifi_rounded,
                    colors: AppColors.accents[0],
                    size: 38,
                  ),
                  title: const Text('Wi-Fi only'),
                  subtitle: const Text(
                    'Downloads wait for Wi-Fi instead of using mobile data.',
                  ),
                  value: wifiOnly,
                  onChanged: manager.setWifiOnly,
                ),
                const Divider(indent: 68),
                ListTile(
                  leading: IconBadge(
                    icon: Icons.stacked_line_chart_rounded,
                    colors: AppColors.accents[1],
                    size: 38,
                  ),
                  title: const Text('Simultaneous downloads'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1')),
                        ButtonSegment(value: 2, label: Text('2')),
                        ButtonSegment(value: 3, label: Text('3')),
                      ],
                      selected: {concurrency},
                      onSelectionChanged: (s) =>
                          manager.setConcurrency(s.single),
                    ),
                  ),
                ),
                const Divider(indent: 68),
                SwitchListTile(
                  secondary: IconBadge(
                    icon: Icons.playlist_add_rounded,
                    colors: AppColors.accents[3],
                    size: 38,
                  ),
                  title: const Text('Add to "Downloads" playlist'),
                  subtitle: const Text(
                    'Finished downloads are also added to a playlist. They '
                    'always appear in your library.',
                  ),
                  value: playlist,
                  onChanged: prefs.setDownloadAddToPlaylist,
                ),
                const Divider(indent: 68),
                ListTile(
                  leading: IconBadge(
                    icon: Icons.high_quality_rounded,
                    colors: AppColors.accents[4],
                    size: 38,
                  ),
                  title: const Text('Jamendo download quality'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'mp32', label: Text('High (VBR)')),
                        ButtonSegment(value: 'mp31', label: Text('96 kbps')),
                      ],
                      selected: {quality},
                      onSelectionChanged: (s) =>
                          prefs.setJamendoQuality(s.single),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Music is saved to Music/AS Media and videos to Movies/AS Media. '
            'Audius tracks download as the MP3 the artist published. Direct '
            'links keep their original quality, so there is no video quality '
            'setting.',
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

final _wifiOnlyProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).watchDownloadWifiOnly(),
);

final _concurrencyProvider = StreamProvider<int>(
  (ref) => ref.watch(preferencesProvider).watchDownloadConcurrency(),
);

final _addToPlaylistProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).watchDownloadAddToPlaylist(),
);
