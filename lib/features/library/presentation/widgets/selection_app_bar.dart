import 'package:flutter/material.dart';

/// Contextual app bar while choosing files to delete.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.allVisibleSelected,
    required this.onClose,
    required this.onSelectAll,
    required this.onDelete,
    this.bottom,
  });

  final int selectedCount;
  final bool allVisibleSelected;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback? onDelete;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel selection',
        onPressed: onClose,
        icon: const Icon(Icons.close),
      ),
      title: Text('$selectedCount selected'),
      actions: [
        IconButton(
          tooltip: allVisibleSelected ? 'Deselect all' : 'Select all',
          onPressed: onSelectAll,
          icon: Icon(allVisibleSelected ? Icons.deselect : Icons.select_all),
        ),
        IconButton(
          tooltip: 'Delete selected',
          onPressed: selectedCount == 0 ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
      bottom: bottom,
    );
  }
}
