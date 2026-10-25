import 'package:video_player/video_player.dart';

enum SubtitleSize { small, medium, large }

/// An external subtitle file loaded for one media item (spec 4.3, P1).
class SubtitleTrack {
  const SubtitleTrack({required this.name, required this.captions});

  final String name;
  final ClosedCaptionFile captions;
}

class SubtitleFormatException implements Exception {
  const SubtitleFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses SRT or WebVTT text. Format is detected from the content first (a
/// `WEBVTT` header), then the file name. Throws [SubtitleFormatException]
/// for anything else or a file without cues.
SubtitleTrack parseSubtitles(String name, String content) {
  final text = content.startsWith('﻿') ? content.substring(1) : content;
  final lower = name.toLowerCase();
  final ClosedCaptionFile file;
  if (text.trimLeft().startsWith('WEBVTT') || lower.endsWith('.vtt')) {
    file = WebVTTCaptionFile(text);
  } else if (lower.endsWith('.srt') || _looksLikeSrt(text)) {
    file = SubRipCaptionFile(text.replaceAll('\r\n', '\n'));
  } else {
    throw const SubtitleFormatException(
      'Only SRT and WebVTT subtitle files are supported.',
    );
  }
  if (file.captions.isEmpty) {
    throw const SubtitleFormatException('No subtitles were found in the file.');
  }
  return SubtitleTrack(name: name, captions: file);
}

final _srtTiming = RegExp(
  r'\d{2}:\d{2}:\d{2},\d{3}\s+-->\s+\d{2}:\d{2}:\d{2},\d{3}',
);

bool _looksLikeSrt(String text) => _srtTiming.hasMatch(text);
