import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/data/app_database.dart';
import 'theme/app_theme.dart';

/// Shown when the local database cannot be opened (e.g. a failed migration).
/// Offers a reset of the library data; media files are never touched.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    super.key,
    required this.error,
    required this.database,
  });

  final Object error;
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'The app\'s library data could not be opened.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your media files are safe. Resetting clears the library '
                    'index, playlists, queue and settings stored by this app '
                    'on this device; synced account data can be restored by '
                    'signing in again.',
                  ),
                  const SizedBox(height: 8),
                  Text('$error', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset library data?'),
                          content: const Text(
                            'This cannot be undone. Media files are not deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      await database.wipe();
                      await SystemNavigator.pop();
                    },
                    child: const Text('Reset library data and close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
