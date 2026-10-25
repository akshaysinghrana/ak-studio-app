/// Default seek step for rewind/forward controls (spec 4.2).
const Duration kSeekStep = Duration(seconds: 10);

/// Restart the current item instead of going back when past this point (spec 7.1).
const Duration kPreviousRestartThreshold = Duration(seconds: 3);

/// Returns [target] clamped to `[0, duration]`. When [duration] is unknown
/// (zero), only the lower bound is enforced.
Duration clampPosition(Duration target, Duration duration) {
  if (target < Duration.zero) return Duration.zero;
  if (duration > Duration.zero && target > duration) return duration;
  return target;
}

/// Position after moving [delta] from [position], kept within the media bounds.
Duration seekBy(Duration position, Duration delta, Duration duration) =>
    clampPosition(position + delta, duration);
