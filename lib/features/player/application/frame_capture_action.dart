import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/platform/frame_capture.dart';

const screenshotAlbum = 'Media Player Screenshots';

/// Captures the decoded frame at [position] (never the Flutter UI), saves it
/// to the gallery album and offers Share; falls back to Share when gallery
/// access is denied (spec 5.3).
Future<void> captureAndSaveFrame(
  BuildContext context, {
  required String locator,
  required Duration position,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final path = await const FrameCapture().capture(
      locator: locator,
      position: position,
    );
    var saved =
        await Gal.hasAccess(toAlbum: true) ||
        await Gal.requestAccess(toAlbum: true);
    String? error;
    if (saved) {
      try {
        await Gal.putImage(path, album: screenshotAlbum);
      } on GalException catch (e) {
        saved = false;
        error = e.type.message;
      }
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Frame saved to "$screenshotAlbum"'
              : error != null
              ? 'Could not save ($error). You can still share the frame.'
              : 'Gallery access denied. You can still share the frame.',
        ),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () =>
              SharePlus.instance.share(ShareParams(files: [XFile(path)])),
        ),
      ),
    );
  } on PlatformException catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'This frame could not be captured: ${e.message ?? e.code}',
        ),
      ),
    );
  }
}
