import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/library/presentation/file_selection.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/shared/data/app_database.dart';

LibraryItem item(String id) => LibraryItem(
  id: id,
  kind: MediaKind.video,
  title: id,
  locator: 'content://$id',
  origin: MediaOrigin.mediaStore,
  addedAt: DateTime.utc(2026),
  available: true,
  lastSeenScan: 1,
);

void main() {
  test('begin starts a selection with one file', () {
    final s = FileSelection()..begin(item('a'));
    expect(s.active, isTrue);
    expect(s.count, 1);
    expect(s.contains('a'), isTrue);
  });

  test('toggle adds and removes files', () {
    final a = item('a');
    final b = item('b');
    final s = FileSelection()..begin(a);
    s.toggle(b);
    expect(s.count, 2);
    s.toggle(a);
    expect(s.contains('a'), isFalse);
    expect(s.count, 1);
  });

  test('select all then select all again deselects the visible set', () {
    final a = item('a');
    final b = item('b');
    final s = FileSelection()..begin(a);
    s.selectAll([a, b]);
    expect(s.allSelected([a, b]), isTrue);
    s.selectAll([a, b]);
    expect(s.count, 0);
    expect(s.allSelected([a, b]), isFalse);
  });

  test('clear leaves selection inactive', () {
    final s = FileSelection()..begin(item('a'));
    s.clear();
    expect(s.active, isFalse);
    expect(s.count, 0);
  });
}
