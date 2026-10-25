import 'package:flutter/material.dart';

import '../../../playback/application/playback_coordinator.dart';

class BackgroundAudioSwitch extends StatelessWidget {
  const BackgroundAudioSwitch({super.key, required this.coordinator});

  final PlaybackCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: coordinator.continueVideoAudioInBackground,
      builder: (context, enabled, _) => SwitchListTile(
        title: const Text('Continue video audio in background'),
        subtitle: const Text(
          'When enabled, video audio can continue while the app is in the '
          'background or the device is locked. The video picture is not '
          'shown on the locked screen.',
        ),
        value: enabled,
        onChanged: (v) => coordinator.continueVideoAudioInBackground.value = v,
      ),
    );
  }
}
