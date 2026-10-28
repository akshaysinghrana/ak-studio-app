import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../application/library_providers.dart';

/// Keeps the library in sync with the device: rescans quietly at start, when
/// the app returns to the foreground and when MediaStore reports changes
/// (files added or deleted by other apps), so deleted files disappear.
class LibraryAutoRefresh extends ConsumerStatefulWidget {
  const LibraryAutoRefresh({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LibraryAutoRefresh> createState() => _LibraryAutoRefreshState();
}

class _LibraryAutoRefreshState extends ConsumerState<LibraryAutoRefresh> {
  StreamSubscription<void>? _changes;
  late final AppLifecycleListener _lifecycle;

  void _refresh() =>
      ref.read(scanControllerProvider.notifier).refreshSilently();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    _changes = ref.read(mediaStoreProvider).changes().listen((_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _changes?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
