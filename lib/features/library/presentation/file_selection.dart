import '../../../shared/data/app_database.dart';

/// In-memory selection of library files for bulk delete.
class FileSelection {
  bool active = false;
  final Map<String, LibraryItem> items = {};

  int get count => items.length;

  bool contains(String id) => items.containsKey(id);

  void begin(LibraryItem item) {
    active = true;
    items
      ..clear()
      ..[item.id] = item;
  }

  void toggle(LibraryItem item) {
    if (!active) return;
    if (items.remove(item.id) == null) items[item.id] = item;
  }

  /// Selects every [visible] item, or clears those items when they are
  /// already all selected.
  void selectAll(Iterable<LibraryItem> visible) {
    final list = visible.toList();
    final allSelected =
        list.isNotEmpty && list.every((i) => items.containsKey(i.id));
    if (allSelected) {
      for (final i in list) {
        items.remove(i.id);
      }
    } else {
      for (final i in list) {
        items[i.id] = i;
      }
    }
  }

  bool allSelected(Iterable<LibraryItem> visible) {
    final list = visible.toList();
    return list.isNotEmpty && list.every((i) => items.containsKey(i.id));
  }

  void clear() {
    active = false;
    items.clear();
  }
}
