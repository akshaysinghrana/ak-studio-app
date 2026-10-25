import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/permissions/media_permissions.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/library_actions.dart';
import '../../player/domain/subtitles.dart';
import 'privacy_screen.dart';
import '../../player/presentation/widgets/background_audio_switch.dart';
import '../../playback/domain/media_source.dart';

/// Settings (spec 4.6). Account and sync arrive in Phase 6; until then no
/// account controls are shown.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Re-read permission status when returning from system settings.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(mediaAccessProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = ref.watch(coordinatorProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;
    final access = ref.watch(mediaAccessProvider).value;
    final scanBusy = ref.watch(scanControllerProvider).busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Account'),
          Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authRepositoryProvider);
              final user = ref.watch(authStateProvider).value;
              return ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(user?.email ?? 'Guest'),
                subtitle: Text(
                  !auth.isConfigured
                      ? 'Accounts are not set up in this build'
                      : user == null
                      ? 'Sign in to sync playlists, favourites and settings'
                      : 'Account and sync',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.account),
              );
            },
          ),
          const _Header('Playback'),
          BackgroundAudioSwitch(coordinator: coordinator),
          const ListTile(
            title: Text('Seek step'),
            subtitle: Text('Rewind and forward move 10 seconds.'),
          ),
          SwitchListTile(
            title: const Text('Brightness gesture'),
            subtitle: const Text(
              'Swipe up or down on the left half of a video. Changes only '
              'this app\'s brightness while the player is open.',
            ),
            value: ref.watch(brightnessGestureProvider).value ?? false,
            onChanged: (v) =>
                ref.read(preferencesProvider).setBrightnessGesture(v),
          ),
          SwitchListTile(
            title: const Text('Volume gesture'),
            subtitle: const Text(
              'Swipe up or down on the right half of a video to change '
              'media volume.',
            ),
            value: ref.watch(volumeGestureProvider).value ?? false,
            onChanged: (v) => ref.read(preferencesProvider).setVolumeGesture(v),
          ),
          ListTile(
            title: const Text('Subtitle size'),
            trailing: DropdownButton<SubtitleSize>(
              value:
                  ref.watch(subtitleSizeProvider).value ?? SubtitleSize.medium,
              onChanged: (v) {
                if (v != null) ref.read(preferencesProvider).setSubtitleSize(v);
              },
              items: const [
                DropdownMenuItem(
                  value: SubtitleSize.small,
                  child: Text('Small'),
                ),
                DropdownMenuItem(
                  value: SubtitleSize.medium,
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: SubtitleSize.large,
                  child: Text('Large'),
                ),
              ],
            ),
          ),
          const _Header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(preferencesProvider).setThemeMode(s.single),
            ),
          ),
          const _Header('Library'),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Scan library'),
            subtitle: const Text(
              'Find MP4 and MP3 files on this device. Files are not uploaded.',
            ),
            enabled: !scanBusy,
            onTap: () => LibraryActions.scan(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Choose files'),
            subtitle: const Text(
              'Add individual files with the system picker.',
            ),
            onTap: () => LibraryActions.importFiles(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Media access'),
            subtitle: Text(
              access == null
                  ? 'Checking…'
                  : 'Videos: ${_label(access[MediaKind.video]!)} · '
                        'Audio: ${_label(access[MediaKind.audio]!)}',
            ),
            trailing: TextButton(
              onPressed: () =>
                  ref.read(mediaPermissionsProvider).openSettings(),
              child: const Text('System settings'),
            ),
          ),
          const _Header('About'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('What stays on this device and what syncs'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open-source licences'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Unified Media Player',
            ),
          ),
          if (kDebugMode) ...[
            const _Header('Developer'),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Engine test screen'),
              onTap: () => context.push(Routes.debugEngine),
            ),
          ],
        ],
      ),
    );
  }

  static String _label(MediaAccess a) => switch (a) {
    MediaAccess.granted => 'allowed',
    MediaAccess.limited => 'selected items only',
    MediaAccess.denied => 'not allowed',
    MediaAccess.permanentlyDenied => 'blocked (change in system settings)',
  };
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}
