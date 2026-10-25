import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../shared/data/app_database.dart';

/// Device-independent identity for a media file, used to match playlist and
/// favourite entries across devices. Only this one-way hash is uploaded; file
/// names, paths, titles and URIs never leave the device (spec 9.3).
String mediaFingerprint(LibraryItem item) {
  final name = (item.displayName ?? item.title).toLowerCase();
  final seconds = ((item.durationMs ?? 0) / 1000).round();
  final input = 'v1|${item.kind.name}|$name|${item.sizeBytes ?? 0}|$seconds';
  return sha256.convert(utf8.encode(input)).toString().substring(0, 32);
}
