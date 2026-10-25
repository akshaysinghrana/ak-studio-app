import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../player/presentation/widgets/background_audio_switch.dart';
import '../player/presentation/widgets/playback_debug_panel.dart';
import '../player/presentation/widgets/player_area.dart';
import '../player/presentation/widgets/queue_list.dart';
import '../player/presentation/widgets/transport_controls.dart';

/// Debug-only engine screen from the Phase 1 proof of concept (spec 8.4).
/// Kept because `scripts/device_lifecycle_checks.py` drives this layout.
class EnginePocScreen extends ConsumerWidget {
  const EnginePocScreen({super.key});

  Future<void> _import(WidgetRef ref, {required bool replace}) async {
    final coordinator = ref.read(coordinatorProvider);
    final result = await ref.read(libraryRepositoryProvider).importDocuments();
    final media = [for (final e in result.imported) e.toMediaSource()];
    if (media.isEmpty) return;
    if (replace) {
      await coordinator.playNow(media);
    } else {
      for (final m in media) {
        await coordinator.addToQueue(m);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(coordinatorProvider);
    final pip = ref.watch(pictureInPictureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Engine proof of concept')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _import(ref, replace: true),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose files'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _import(ref, replace: false),
                  icon: const Icon(Icons.queue),
                  label: const Text('Add to queue'),
                ),
              ],
            ),
          ),
          PlayerArea(coordinator: coordinator, pip: pip),
          PlaybackErrorBanner(coordinator: coordinator),
          TransportControls(coordinator: coordinator),
          BackgroundAudioSwitch(coordinator: coordinator),
          QueueList(coordinator: coordinator),
          if (kDebugMode) PlaybackDebugPanel(coordinator: coordinator),
        ],
      ),
    );
  }
}
