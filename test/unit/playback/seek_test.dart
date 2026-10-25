import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/playback/domain/seek.dart';

void main() {
  const d = Duration(seconds: 60);

  group('seekBy', () {
    test('moves exactly 10 seconds inside bounds', () {
      expect(
        seekBy(const Duration(seconds: 20), kSeekStep, d),
        const Duration(seconds: 30),
      );
      expect(
        seekBy(const Duration(seconds: 20), -kSeekStep, d),
        const Duration(seconds: 10),
      );
    });

    test('never goes before zero', () {
      expect(seekBy(const Duration(seconds: 4), -kSeekStep, d), Duration.zero);
    });

    test('never goes past the end', () {
      expect(seekBy(const Duration(seconds: 55), kSeekStep, d), d);
    });

    test('short file (<10s) clamps both ways', () {
      const short = Duration(seconds: 6);
      expect(seekBy(const Duration(seconds: 3), kSeekStep, short), short);
      expect(
        seekBy(const Duration(seconds: 3), -kSeekStep, short),
        Duration.zero,
      );
    });

    test('unknown duration only clamps the lower bound', () {
      expect(
        seekBy(const Duration(seconds: 5), kSeekStep, Duration.zero),
        const Duration(seconds: 15),
      );
      expect(
        seekBy(const Duration(seconds: 5), -kSeekStep, Duration.zero),
        Duration.zero,
      );
    });
  });
}
