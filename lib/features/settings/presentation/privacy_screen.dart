import 'package:flutter/material.dart';

/// In-app privacy summary (spec 9.3). Placeholder for the full policy, which
/// must be published before a public release (docs/PRIVACY.md).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: text.titleMedium)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          section(
            'Your media stays on this device',
            'Videos and music are played from your device. They are never '
                'uploaded. The library index, playback positions, queue and '
                'history are stored only in this app\'s local database.',
          ),
          section(
            'Permissions',
            'Media access (videos and audio) is requested only when you scan '
                'the library. Files you choose with the system picker need no '
                'permission. The app never asks for access to all files or to '
                'your photos.',
          ),
          section(
            'If you sign in',
            'Only playlists you add to your account, favourites and app '
                'settings are synced. Files are referred to by anonymous '
                'fingerprints, not names or paths. Listening and viewing history '
                'is not synced. You can sign out and keep your data on this '
                'device, or delete your account and its synced data.',
          ),
          section(
            'Analytics and ads',
            'There are no analytics, tracking or ads.',
          ),
          section(
            'Screenshots',
            'Frames you capture are saved to the "AS Media Screenshots" '
                'album on your device and shared only when you choose to.',
          ),
        ],
      ),
    );
  }
}
