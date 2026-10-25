import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/platform/picture_in_picture.dart';
import 'features/playback/application/playback_coordinator.dart';
import 'features/playback/domain/media_source.dart';
import 'features/poc/engine_poc_screen.dart';

/// Debug-only: `--dart-define=UMP_DEBUG_AUTOLOAD=/path/a.mp4;/path/b.mp3`
/// queues files on start so device test scripts can skip the system picker.
/// Ignored in profile/release builds.
const _debugAutoload = String.fromEnvironment('UMP_DEBUG_AUTOLOAD');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final coordinator = await PlaybackCoordinator.init();
  final pip = PictureInPicture();
  runApp(MediaPlayerApp(coordinator: coordinator, pip: pip));
  if (kDebugMode && _debugAutoload.isNotEmpty) {
    for (final path in _debugAutoload.split(';')) {
      final media = MediaSource.fromFile(
        path: path,
        name: path.split('/').last,
      );
      if (media != null) await coordinator.addToQueue(media);
    }
  }
}

class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({
    super.key,
    required this.coordinator,
    required this.pip,
  });

  final PlaybackCoordinator coordinator;
  final PictureInPicture pip;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3D7BFD);
    return MaterialApp(
      title: 'Unified Media Player',
      themeMode: ThemeMode.dark,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: EnginePocScreen(coordinator: coordinator, pip: pip),
    );
  }
}
