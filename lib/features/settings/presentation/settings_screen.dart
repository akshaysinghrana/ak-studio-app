import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';
import '../../../core/permissions/media_permissions.dart';
import '../../../core/platform/screen_control.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/hidden_folders_screen.dart';
import '../../library/presentation/library_actions.dart';
import '../../player/domain/subtitles.dart';
import '../../playback/domain/media_source.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';

final batteryUnrestrictedProvider = FutureProvider.autoDispose<bool>(
  (ref) => const ScreenControl().isBatteryUnrestricted(),
);

/// Settings (spec 4.6), grouped into cards.
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
    // Re-read permission and battery status when returning from system
    // settings.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(mediaAccessProvider);
        ref.invalidate(batteryUnrestrictedProvider);
      },
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
    final unrestricted = ref.watch(batteryUnrestrictedProvider).value ?? true;
    final auth = ref.watch(authRepositoryProvider);
    final user = ref.watch(authStateProvider).value;
    final prefs = ref.read(preferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Group(
            title: 'Account',
            children: [
              _Item(
                icon: Icons.person_rounded,
                colors: AppColors.accents[1],
                title: user?.email ?? 'Guest',
                subtitle: !auth.isConfigured
                    ? 'Accounts are not set up in this build'
                    : user == null
                    ? 'Sign in to sync playlists, favourites and settings'
                    : 'Account and sync',
                onTap: () => context.push(Routes.account),
              ),
            ],
          ),
          _Group(
            title: 'Playback',
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: coordinator.continueVideoAudioInBackground,
                builder: (context, on, _) => _SwitchItem(
                  icon: Icons.headphones_rounded,
                  colors: AppColors.accents[0],
                  title: 'Continue video audio in background',
                  subtitle:
                      'Keeps a video\'s sound playing when the app is in the '
                      'background or the phone is locked. The picture is not '
                      'shown on the lock screen.',
                  value: on,
                  onChanged: (v) =>
                      coordinator.continueVideoAudioInBackground.value = v,
                ),
              ),
              _Item(
                icon: unrestricted
                    ? Icons.battery_full_rounded
                    : Icons.battery_alert_rounded,
                colors: unrestricted
                    ? AppColors.accents[3]
                    : AppColors.accents[4],
                title: 'Background playback',
                subtitle: unrestricted
                    ? 'Battery use is unrestricted: playback can keep running '
                          'with the screen locked.'
                    : 'Battery optimisation may stop playback in the '
                          'background on some phones. Tap, then choose '
                          'Battery → Unrestricted.',
                onTap: () => const ScreenControl().openBatterySettings(),
              ),
              const _Item(
                icon: Icons.fast_forward_rounded,
                title: 'Seek step',
                subtitle:
                    'Double-tap left/right or the ±10 buttons move 10 '
                    'seconds.',
              ),
              _SwitchItem(
                icon: Icons.brightness_6_rounded,
                colors: AppColors.accents[4],
                title: 'Brightness gesture',
                subtitle: 'Swipe up/down on the left half of a video.',
                value: ref.watch(brightnessGestureProvider).value ?? false,
                onChanged: prefs.setBrightnessGesture,
              ),
              _SwitchItem(
                icon: Icons.volume_up_rounded,
                colors: AppColors.accents[5],
                title: 'Volume gesture',
                subtitle: 'Swipe up/down on the right half of a video.',
                value: ref.watch(volumeGestureProvider).value ?? false,
                onChanged: prefs.setVolumeGesture,
              ),
              _Item(
                icon: Icons.subtitles_rounded,
                colors: AppColors.accents[2],
                title: 'Subtitle size',
                trailing: DropdownButton<SubtitleSize>(
                  value:
                      ref.watch(subtitleSizeProvider).value ??
                      SubtitleSize.medium,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(AppTokens.radiusS),
                  onChanged: (v) {
                    if (v != null) prefs.setSubtitleSize(v);
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
            ],
          ),
          _Group(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('System'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) => prefs.setThemeMode(s.single),
                  ),
                ),
              ),
            ],
          ),
          _Group(
            title: 'Library',
            children: [
              _Item(
                icon: Icons.radar_rounded,
                title: 'Scan library',
                subtitle: 'Find MP4 and MP3 files on this phone. Nothing is uploaded.',
                onTap: scanBusy
                    ? null
                    : () => LibraryActions.scan(context, ref),
              ),
              _Item(
                icon: Icons.folder_open_rounded,
                colors: AppColors.accents[5],
                title: 'Choose files',
                subtitle: 'Add individual files with the system picker.',
                onTap: () => LibraryActions.importFiles(context, ref),
              ),
              _Item(
                icon: Icons.visibility_off_rounded,
                colors: AppColors.accents[1],
                title: 'Hidden folders',
                subtitle:
                    '${ref.watch(hiddenFoldersProvider).value?.length ?? 0} hidden',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HiddenFoldersScreen(),
                  ),
                ),
              ),
              _Item(
                icon: Icons.history_rounded,
                colors: AppColors.accents[4],
                title: 'Clear watch history',
                subtitle: 'Continue list and resume positions',
                onTap: () => LibraryActions.confirmClearHistory(context, ref),
              ),
              _Item(
                icon: Icons.lock_rounded,
                colors: AppColors.accents[3],
                title: 'Media access',
                subtitle: access == null
                    ? 'Checking…'
                    : 'Videos: ${_label(access[MediaKind.video]!)} · '
                          'Audio: ${_label(access[MediaKind.audio]!)}',
                onTap: () => ref.read(mediaPermissionsProvider).openSettings(),
              ),
            ],
          ),
          _Group(
            title: 'About',
            children: [
              _Item(
                leading: const AppLogo(size: 40),
                title: 'About AS Media',
                subtitle: 'Created by Akshay Studio',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
              ),
              _Item(
                icon: Icons.privacy_tip_rounded,
                colors: AppColors.accents[3],
                title: 'Privacy',
                subtitle: 'What stays on this device and what syncs',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyScreen(),
                  ),
                ),
              ),
              _Item(
                icon: Icons.description_rounded,
                colors: AppColors.accents[5],
                title: 'Open-source licences',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'AS Media',
                  applicationLegalese: '© 2026 Akshay Studio',
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: AppLogo(size: 64),
                  ),
                ),
              ),
            ],
          ),
          if (kDebugMode)
            _Group(
              title: 'Developer',
              children: [
                _Item(
                  icon: Icons.bug_report_rounded,
                  colors: AppColors.accents[2],
                  title: 'Engine test screen',
                  onTap: () => context.push(Routes.debugEngine),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'AS Media · Created by Akshay Studio',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
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

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title, padding: const EdgeInsets.fromLTRB(20, 18, 8, 8)),
      GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const Divider(indent: 68),
              c,
            ],
          ],
        ),
      ),
    ],
  );
}

class _Item extends StatelessWidget {
  const _Item({
    this.icon,
    this.leading,
    this.colors = const [AppColors.blueDeep, AppColors.cyan],
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData? icon;
  final Widget? leading;
  final List<Color> colors;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: leading ?? IconBadge(icon: icon!, colors: colors, size: 38),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    onTap: onTap,
  );
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    secondary: IconBadge(icon: icon, colors: colors, size: 38),
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );
}
