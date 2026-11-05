import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/downloads/domain/download_rules.dart';
import 'package:video_music_app/features/playback/domain/media_source.dart';

void main() {
  test('YouTube and its video hosts are always refused', () {
    for (final url in [
      'https://www.youtube.com/watch?v=abc',
      'https://youtu.be/abc',
      'https://music.youtube.com/watch?v=abc',
      'https://rr1---sn-abc.googlevideo.com/videoplayback?x=1',
      'https://www.youtube-nocookie.com/embed/abc',
    ]) {
      expect(DownloadRules.validateUrl(url), contains('YouTube'), reason: url);
    }
    expect(DownloadRules.isBlockedHost('notyoutube.com'), isFalse);
  });

  test('only full http(s) links are accepted', () {
    expect(DownloadRules.validateUrl('ftp://x/a.mp3'), isNotNull);
    expect(DownloadRules.validateUrl('song.mp3'), isNotNull);
    expect(DownloadRules.validateUrl('https://cdn.example/a.mp3'), isNull);
  });

  test('kind from MIME type, else from the file name', () {
    expect(
      DownloadRules.kindFor(mimeType: 'audio/mpeg; charset=x'),
      MediaKind.audio,
    );
    expect(DownloadRules.kindFor(mimeType: 'video/mp4'), MediaKind.video);
    expect(
      DownloadRules.kindFor(
        mimeType: 'application/octet-stream',
        fileName: 'clip.MP4',
      ),
      MediaKind.video,
    );
    expect(DownloadRules.kindFor(mimeType: 'text/html'), isNull);
    expect(DownloadRules.kindFor(fileName: 'a.flac'), isNull);
  });

  test('file names are safe', () {
    expect(
      DownloadRules.fileName('A/B: "C"?', MediaKind.audio, artist: 'X*Y'),
      'X_Y - A_B_ _C__.mp3',
    );
    expect(DownloadRules.fileName('  ', MediaKind.video), 'download.mp4');
    expect(
      DownloadRules.fileName('a' * 300, MediaKind.audio).length,
      lessThanOrEqualTo(124),
    );
  });

  test('file headers identify MP3 and MP4', () {
    expect(
      DownloadRules.looksLike([0x49, 0x44, 0x33, 4], MediaKind.audio),
      isTrue,
    );
    expect(
      DownloadRules.looksLike([0xFF, 0xFB, 0x90], MediaKind.audio),
      isTrue,
    );
    expect(
      DownloadRules.looksLike('<html>'.codeUnits, MediaKind.audio),
      isFalse,
    );
    expect(
      DownloadRules.looksLike([
        0,
        0,
        0,
        0x20,
        0x66,
        0x74,
        0x79,
        0x70,
        0x69,
      ], MediaKind.video),
      isTrue,
    );
  });

  test('relative folder of a shared-storage path', () {
    expect(
      DownloadRules.relativeFolder(
        '/storage/emulated/0/Music/AS Media/a b.mp3',
      ),
      'Music/AS Media/',
    );
    expect(
      DownloadRules.relativeFolder('/storage/1A2B-3C4D/Movies/AS Media/v.mp4'),
      'Movies/AS Media/',
    );
  });
}
