import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/player/domain/subtitles.dart';
import 'package:video_music_app/features/playback/domain/sleep_timer.dart';

const srt =
    '1\r\n00:00:01,000 --> 00:00:02,500\r\nHello\r\n\r\n'
    '2\r\n00:00:03,000 --> 00:00:04,000\r\nWorld\r\n';

const vtt =
    'WEBVTT\n\n00:00:01.000 --> 00:00:02.500\nHello\n\n'
    '00:00:03.000 --> 00:00:04.000\nWorld\n';

void main() {
  test('parses SRT with CRLF line endings', () {
    final t = parseSubtitles('movie.srt', srt);
    expect(t.captions.captions, hasLength(2));
    expect(t.captions.captions.first.text, 'Hello');
    expect(t.captions.captions.first.start, const Duration(seconds: 1));
  });

  test('parses WebVTT by header even with an odd file name', () {
    final t = parseSubtitles('download.txt', vtt);
    expect(t.captions.captions.last.text, 'World');
  });

  test('detects SRT content with a byte-order mark and unknown extension', () {
    final t = parseSubtitles('subs', '﻿$srt');
    expect(t.captions.captions, hasLength(2));
  });

  test('rejects unsupported or empty files', () {
    expect(
      () => parseSubtitles('a.ass', '[Script Info]'),
      throwsA(isA<SubtitleFormatException>()),
    );
    expect(
      () => parseSubtitles('a.srt', ''),
      throwsA(isA<SubtitleFormatException>()),
    );
  });

  test('sleep timer remaining time never goes negative', () {
    final now = DateTime(2026, 1, 1, 12);
    final timer = SleepTimer.after(now.add(const Duration(minutes: 5)));
    expect(timer.remaining(now), const Duration(minutes: 5));
    expect(timer.remaining(now.add(const Duration(hours: 1))), Duration.zero);
    expect(const SleepTimer.endOfItem().remaining(now), isNull);
  });
}
