import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../playback/application/playback_coordinator.dart';
import '../../../playback/domain/sleep_timer.dart';
import '../../domain/subtitles.dart';

String speedLabel(double s) =>
    '${s == s.roundToDouble() ? s.toStringAsFixed(0) : s}x';

Future<void> showSpeedSheet(
  BuildContext context,
  PlaybackCoordinator coordinator,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: RadioGroup<double>(
        groupValue: coordinator.speed.value,
        onChanged: (v) {
          if (v != null) coordinator.setSpeed(v);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Playback speed')),
            for (final s in kPlaybackSpeeds)
              RadioListTile<double>(
                value: s,
                title: Text(s == 1.0 ? 'Normal (1x)' : speedLabel(s)),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showSleepTimerSheet(
  BuildContext context,
  PlaybackCoordinator coordinator,
) {
  const minutes = [5, 10, 15, 30, 45, 60, 90];
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Sleep timer')),
          if (coordinator.sleepTimer.value != null)
            ListTile(
              leading: const Icon(Icons.timer_off_outlined),
              title: const Text('Turn off'),
              onTap: () {
                coordinator.setSleepTimer();
                Navigator.pop(context);
              },
            ),
          for (final m in minutes)
            ListTile(
              title: Text('$m minutes'),
              onTap: () {
                coordinator.setSleepTimer(after: Duration(minutes: m));
                Navigator.pop(context);
              },
            ),
          ListTile(
            title: const Text('End of current item'),
            onTap: () {
              coordinator.setSleepTimer(endOfItem: true);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

/// Subtitles: load an SRT/VTT file, turn off, size and delay (spec 4.3).
Future<void> showSubtitleSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (context) => const SafeArea(child: _SubtitleSheet()),
  );
}

class _SubtitleSheet extends ConsumerWidget {
  const _SubtitleSheet();

  static const _step = Duration(milliseconds: 250);

  Future<void> _load(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final importer = ref.read(documentImporterProvider);
    final coordinator = ref.read(coordinatorProvider);
    try {
      final uri = await importer.pickSubtitle();
      if (uri == null) return;
      final text = await importer.readText(uri);
      final name = Uri.decodeComponent(uri.split('/').last.split('%2F').last);
      await coordinator.setSubtitles(parseSubtitles(name, text));
      navigator.pop();
    } on SubtitleFormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on PlatformException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not read the file: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    final size = ref.watch(subtitleSizeProvider).value ?? SubtitleSize.medium;
    return ListenableBuilder(
      listenable: Listenable.merge([
        coordinator.subtitles,
        coordinator.subtitleOffset,
      ]),
      builder: (context, _) {
        final track = coordinator.subtitles.value;
        final offset = coordinator.subtitleOffset.value;
        return ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Subtitles')),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: Text(
                track == null
                    ? 'Load subtitle file (SRT, VTT)'
                    : 'Replace file',
              ),
              subtitle: track == null ? null : Text(track.name),
              onTap: () => _load(context, ref),
            ),
            if (track != null) ...[
              ListTile(
                leading: const Icon(Icons.subtitles_off_outlined),
                title: const Text('Turn off subtitles'),
                onTap: () => coordinator.setSubtitles(null),
              ),
              ListTile(
                title: const Text('Delay'),
                subtitle: Text(
                  '${offset.inMilliseconds >= 0 ? '+' : ''}'
                  '${(offset.inMilliseconds / 1000).toStringAsFixed(2)} s',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Show subtitles earlier',
                      onPressed: () =>
                          coordinator.setSubtitleOffset(offset - _step),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: 'Show subtitles later',
                      onPressed: () =>
                          coordinator.setSubtitleOffset(offset + _step),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<SubtitleSize>(
                segments: const [
                  ButtonSegment(
                    value: SubtitleSize.small,
                    label: Text('Small'),
                  ),
                  ButtonSegment(
                    value: SubtitleSize.medium,
                    label: Text('Medium'),
                  ),
                  ButtonSegment(
                    value: SubtitleSize.large,
                    label: Text('Large'),
                  ),
                ],
                selected: {size},
                onSelectionChanged: (s) =>
                    ref.read(preferencesProvider).setSubtitleSize(s.single),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Embedded audio tracks; callers show this only when there are 2 or more.
Future<void> showAudioTrackSheet(
  BuildContext context,
  PlaybackCoordinator coordinator,
) async {
  final tracks = await coordinator.audioTracks();
  if (!context.mounted) return;
  final selected = tracks.where((t) => t.isSelected).firstOrNull?.id;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: RadioGroup<String>(
        groupValue: selected,
        onChanged: (id) {
          if (id != null) coordinator.selectAudioTrack(id);
          Navigator.pop(context);
        },
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Audio track')),
            for (final (i, t) in tracks.indexed)
              RadioListTile<String>(
                value: t.id,
                title: Text(t.label ?? t.language ?? 'Track ${i + 1}'),
                subtitle: t.language != null && t.label != null
                    ? Text(t.language!)
                    : null,
              ),
          ],
        ),
      ),
    ),
  );
}
