import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/player/domain/video_gestures.dart';

void main() {
  DoubleTapAction at(double x, {bool zoomed = false}) =>
      doubleTapAction(x: x, width: 300, zoomed: zoomed);

  test('outer thirds seek, centre zooms', () {
    expect(at(10), DoubleTapAction.rewind);
    expect(at(150), DoubleTapAction.zoomIn);
    expect(at(290), DoubleTapAction.forward);
  });

  test('while zoomed every double-tap resets zoom and never seeks', () {
    for (final x in [10.0, 150.0, 290.0]) {
      expect(at(x, zoomed: true), DoubleTapAction.resetZoom);
    }
  });

  test('zero width falls back to zoom', () {
    expect(
      doubleTapAction(x: 5, width: 0, zoomed: false),
      DoubleTapAction.zoomIn,
    );
  });
}
