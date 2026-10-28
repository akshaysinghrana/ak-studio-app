import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/brand_widgets.dart';
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brand,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.45),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTokens.spaceL),
            Text(
              message,
              style: text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceS),
            Text(
              'Scan finds MP4 videos and MP3 music on this phone and asks for '
              'media access only then. Or pick individual files. Your media '
              'never leaves your device.',
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceL),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                GradientButton(
                  label: 'Scan library',
                  icon: Icons.radar_rounded,
                  onPressed: scan.busy
                      ? null
                      : () => LibraryActions.scan(context, ref),
                ),
                OutlinedButton.icon(
                  onPressed: () => LibraryActions.importFiles(context, ref),
                  icon: const Icon(Icons.folder_open_rounded),
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
