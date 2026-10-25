/// Sleep timer (spec 6.3): pause after a duration, or at the end of the
/// current item.
class SleepTimer {
  const SleepTimer.after(DateTime this.endsAt) : endOfItem = false;

  const SleepTimer.endOfItem() : endsAt = null, endOfItem = true;

  final DateTime? endsAt;
  final bool endOfItem;

  /// Time left at [now], or null for end-of-item timers.
  Duration? remaining(DateTime now) {
    final end = endsAt;
    if (end == null) return null;
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// Playback speeds offered in the UI (spec 4.2).
const kPlaybackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
