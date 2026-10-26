import 'package:flutter_test/flutter_test.dart';
import 'package:video_music_app/features/player/domain/video_gestures.dart';

void main() {
  DoubleTapAction at(double x) => doubleTapAction(x: x, width: 300);

  test('left half rewinds, right half forwards', () {
    expect(at(0), DoubleTapAction.rewind);
    expect(at(149), DoubleTapAction.rewind);
    expect(at(150), DoubleTapAction.forward);
    expect(at(299), DoubleTapAction.forward);
  });
}
