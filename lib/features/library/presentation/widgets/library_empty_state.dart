import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../application/library_providers.dart';
import '../library_actions.dart';

/// First-launch / empty library state (spec 3): explains local access and
/// offers both scanning and picking files. Works for guests and offline.
class LibraryEmptyState extends ConsumerWidget {
  const LibraryEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppTokens.spaceM),
            Text(message, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.spaceS),
            Text(
              'Scan finds MP4 videos and MP3 audio on this device and asks for '
              'media access only then. Or choose individual files. Your media '
              'stays on this device.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceL),
            Wrap(
              spacing: AppTokens.spaceS,
              runSpacing: AppTokens.spaceS,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: scan.busy
                      ? null
                      : () => LibraryActions.scan(context, ref),
                  icon: const Icon(Icons.search),
                  label: const Text('Scan library'),
                ),
                OutlinedButton.icon(
                  onPressed: () => LibraryActions.importFiles(context, ref),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choose files'),
                ),
              ],
            ),
            if (scan.busy) ...[
              const SizedBox(height: AppTokens.spaceM),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin progress strip shown while a scan runs.
class ScanProgressBar extends ConsumerWidget {
  const ScanProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    if (!scan.busy) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      label: scan.status == ScanStatus.scanning
          ? 'Scanning, ${scan.scanned} files found'
          : 'Waiting for media access',
      child: const LinearProgressIndicator(),
    );
  }
}
