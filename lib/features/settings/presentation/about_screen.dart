import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/brand_widgets.dart';

/// App identity: logo, version and "Created by Akshay Studio".
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.45),
                    blurRadius: 48,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const AppLogo(size: 140),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: GradientText(
              'AS Media',
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Center(
            child: Text(
              'Version $version',
              style: text.bodyMedium?.copyWith(color: muted),
            ),
          ),
          const SizedBox(height: 28),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Created by',
                  style: text.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 4),
                GradientText(
                  'Akshay Studio',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'A video and music player for the files on your phone: '
                  'folders, playlists, background playback and more, with your '
                  'media never leaving your device.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2026 Akshay Studio. All rights reserved.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
