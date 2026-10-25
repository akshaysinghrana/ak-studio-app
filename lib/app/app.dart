import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/player/presentation/widgets/player_area.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

class MediaPlayerApp extends ConsumerWidget {
  const MediaPlayerApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;
    final pip = ref.watch(pictureInPictureProvider);
    final coordinator = ref.watch(coordinatorProvider);
    return MaterialApp.router(
      title: 'Unified Media Player',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      // In picture-in-picture only the video is drawn, without controls.
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: pip.isActive,
        builder: (context, inPip, _) =>
            inPip ? PipView(coordinator: coordinator) : child!,
      ),
    );
  }
}
