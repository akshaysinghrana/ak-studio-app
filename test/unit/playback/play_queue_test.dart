import 'dart:math';

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

  List<String> ids(PlayQueue q) => [for (final e in q.entries) e.entryId];

  group('edits never disturb the current item', () {
    final q = PlayQueue.of([
      entry('a'),
      entry('b'),
      entry('c'),
      entry('d'),
    ], currentIndex: 1);

    test('remove upcoming and earlier entries', () {
      expect(ids(q.removeAt(3)), ['a', 'b', 'c']);
      final earlier = q.removeAt(0);
      expect(ids(earlier), ['b', 'c', 'd']);
      expect(earlier.current!.entryId, 'b');
    });

    test('the current entry cannot be removed', () {
      expect(identical(q.removeAt(1), q), isTrue);
    });

    test('reorder keeps the same current entry', () {
      final moved = q.move(3, 0);
      expect(ids(moved), ['d', 'a', 'b', 'c']);
      expect(moved.current!.entryId, 'b');
      final currentMoved = q.move(1, 3);
      expect(currentMoved.current!.entryId, 'b');
      expect(currentMoved.currentIndex, 3);
    });

    test('clear upcoming keeps history and current', () {
      final cleared = q.clearUpcoming();
      expect(ids(cleared), ['a', 'b']);
      expect(cleared.current!.entryId, 'b');
      expect(cleared.upcomingCount, 0);
    });
  });

  group('repeat', () {
    final q = PlayQueue.of([entry('a'), entry('b')], currentIndex: 1);

    test('off stops at the end', () {
      expect(q.onCompletion, CompletionAction.stop);
      expect(q.hasNext, isFalse);
      expect(q.next().currentIndex, 1);
    });

    test('all wraps to the start', () {
      final all = q.withRepeat(QueueRepeat.all);
      expect(all.onCompletion, CompletionAction.advance);
      expect(all.next().currentIndex, 0);
      expect(all.hasNext, isTrue);
    });

    test('one restarts the current item on completion', () {
      expect(
        q.withRepeat(QueueRepeat.one).onCompletion,
        CompletionAction.restartCurrent,
      );
    });

    test('empty queue stops', () {
      expect(const PlayQueue.empty().onCompletion, CompletionAction.stop);
    });
  });

  group('shuffle', () {
    final q = PlayQueue.of([
      for (final id in 'abcdefgh'.split('')) entry(id),
    ], currentIndex: 3);

    test('current item first, every entry exactly once', () {
      final s = q.shuffle(Random(1));
      expect(s.current!.entryId, 'd');
      expect(s.currentIndex, 0);
      expect(ids(s).toSet(), ids(q).toSet());
      expect(ids(s), hasLength(8));
      expect(s.shuffled, isTrue);
    });

    test('walking a shuffled queue plays every item once before stopping', () {
      var s = q.shuffle(Random(2));
      final played = [s.current!.entryId];
      while (s.onCompletion == CompletionAction.advance) {
        s = s.next();
        played.add(s.current!.entryId);
      }
      expect(played.toSet(), hasLength(8));
      expect(played, hasLength(8));
    });

    test('unshuffle restores order, keeps current, keeps additions', () {
      final s = q.shuffle(Random(3)).next().append(entry('z'));
      final current = s.current!.entryId;
      final u = s.unshuffle();
      expect(ids(u), [...'abcdefgh'.split(''), 'z']);
      expect(u.current!.entryId, current);
      expect(u.shuffled, isFalse);
    });

    test(
      'play next while shuffled lands right after current in both orders',
      () {
        final s = q.shuffle(Random(4)).playNext(entry('n'));
        expect(s.entries[s.currentIndex + 1].entryId, 'n');
        final u = s.unshuffle();
        expect(u.entries[u.currentIndex + 1].entryId, 'n');
      },
    );
  });
}
