enum DoubleTapAction { rewind, forward }

/// Double-tap on the left half rewinds and on the right half forwards by the
/// seek step, at any zoom level. Zoom is pinch-only, so zooming and panning
/// never trigger a seek (spec 5.2, 4.2).
DoubleTapAction doubleTapAction({required double x, required double width}) =>
    x < width / 2 ? DoubleTapAction.rewind : DoubleTapAction.forward;

/// Consecutive taps on the same side within this window keep seeking
/// (+10 s each), like popular video apps.
const kSeekChainWindow = Duration(milliseconds: 700);

enum VideoFit { contain, cover, stretch }
