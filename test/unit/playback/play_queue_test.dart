import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';
import 'package:video_music_app/features/playback/domain/play_queue.dart';

QueueEntry entry(String id, [String? mediaId]) => QueueEntry(
  entryId: id,
  media: MediaSource(
    id: mediaId ?? id,
    title: id,
    locator: '/tmp/$id.mp3',
    kind: MediaKind.audio,
  ),
);

void main() {
  test('empty queue has no current item', () {
    const q = PlayQueue.empty();
    expect(q.current, isNull);
    expect(q.hasNext, isFalse);
  });

  test('playNext inserts right after current without moving current', () {
    final q = PlayQueue.of([
      entry('a'),
      entry('b'),
      entry('c'),
    ], currentIndex: 1);
    final next = q.playNext(entry('x'));
    expect(next.entries.map((e) => e.entryId), ['a', 'b', 'x', 'c']);
    expect(next.current!.entryId, 'b');
  });

  test('append keeps current item', () {
    final q = PlayQueue.of([entry('a'), entry('b')]).append(entry('c'));
    expect(q.current!.entryId, 'a');
    expect(q.entries.length, 3);
  });

  test('duplicates of the same media are preserved as separate entries', () {
    final q = PlayQueue.of([entry('e1', 'song')]).append(entry('e2', 'song'));
    expect(q.entries.map((e) => e.media.id), ['song', 'song']);
  });

  test('next/previous stay in bounds', () {
    final q = PlayQueue.of([entry('a'), entry('b')]);
    expect(q.previous().currentIndex, 0);
    expect(q.next().currentIndex, 1);
    expect(q.next().next().currentIndex, 1);
  });

  group('previousAction (3 second rule)', () {
    final q = PlayQueue.of([entry('a'), entry('b')], currentIndex: 1);

    test('restarts after 3 seconds', () {
      expect(
        q.previousAction(const Duration(seconds: 4)),
        PreviousAction.restartCurrent,
      );
    });

    test('goes back within 3 seconds', () {
      expect(
        q.previousAction(const Duration(seconds: 2)),
        PreviousAction.goToPrevious,
      );
    });

    test('restarts when there is no previous item', () {
      expect(
        q.jumpTo(0).previousAction(Duration.zero),
        PreviousAction.restartCurrent,
      );
    });
  });

  test('rejects an out-of-range current index', () {
    expect(() => PlayQueue.of([entry('a')], currentIndex: 2), throwsRangeError);
  });
}
