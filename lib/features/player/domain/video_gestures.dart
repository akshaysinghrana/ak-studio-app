enum DoubleTapAction { rewind, forward, zoomIn, resetZoom }

/// Gesture arbitration for the video surface (spec 5.2, 4.2): while zoomed a
/// double-tap only resets zoom, so zooming never triggers a seek. At 1x the
/// outer thirds seek by the step and the centre zooms in.
DoubleTapAction doubleTapAction({
  required double x,
  required double width,
  required bool zoomed,
}) {
  if (zoomed) return DoubleTapAction.resetZoom;
  if (width <= 0) return DoubleTapAction.zoomIn;
  final fraction = x / width;
  if (fraction < 1 / 3) return DoubleTapAction.rewind;
  if (fraction > 2 / 3) return DoubleTapAction.forward;
  return DoubleTapAction.zoomIn;
}

enum VideoFit { contain, cover, stretch }
