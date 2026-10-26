import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../application/library_providers.dart';
import 'widgets/folder_tile.dart';

/// Lists hidden folders with a Show action for each.
class HiddenFoldersScreen extends ConsumerWidget {
  const HiddenFoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hiddenFoldersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hidden folders')),
      body: hidden.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (folders) => folders.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTokens.spaceL),
                  child: Text(
                    'No hidden folders. Use "Hide folder" in the Folders view '
                    'to keep a folder out of your library.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                children: [
                  const ListTile(
                    dense: true,
                    title: Text(
                      'Hidden folders are left out of Home, lists and search. '
                      'Nothing is deleted.',
                    ),
                  ),
                  for (final f in folders)
                    ListTile(
                      leading: const Icon(Icons.visibility_off_outlined),
                      title: Text(_name(f)),
                      subtitle: Text(f),
                      trailing: TextButton(
                        onPressed: () => setFolderHidden(
                          context,
                          ref,
                          f,
                          _name(f),
                          hidden: false,
                        ),
                        child: const Text('Show'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  static String _name(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }
}
