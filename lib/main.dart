import 'package:flutter/material.dart';

import 'features/playback/application/playback_coordinator.dart';
import 'features/poc/engine_poc_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final coordinator = await PlaybackCoordinator.init();
  runApp(MediaPlayerApp(coordinator: coordinator));
}

class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({super.key, required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3D7BFD);
    return MaterialApp(
      title: 'Unified Media Player',
      themeMode: ThemeMode.dark,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: EnginePocScreen(coordinator: coordinator),
    );
  }
}
