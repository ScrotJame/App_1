/// Review spacing by word level. This is the only schedule the app keeps:
/// nothing is stored, the next review is always derived from the word's
/// `level` and `lastReviewed`.
class SetTimeHelper {
  /// How long a word has to rest after a review that counted, before a
  /// correct answer can raise its level again.
  static Duration reviewInterval(int level) {
    switch (level) {
      case 0:
        return const Duration(minutes: 5);
      case 1:
        return const Duration(minutes: 15);
      case 2:
        return const Duration(minutes: 45);
      case 3:
        return const Duration(hours: 1);
      case 4:
        return const Duration(hours: 2);
      default:
        return const Duration(days: 8);
    }
  }

  /// Whether a correct answer at [now] may raise the level. A word that was
  /// never reviewed is always due.
  static bool isDue(int level, DateTime? lastReviewed, DateTime now) {
    if (lastReviewed == null) return true;
    return !now.isBefore(lastReviewed.add(reviewInterval(level)));
  }

  /// When to remind the user about a word reviewed at [lastReviewed].
  ///
  /// Never earlier than the moment the word becomes due. Short intervals
  /// (level 0–4) skip the sleeping hours (00:00–06:00).
  static DateTime reminderTime(int level, DateTime lastReviewed) {
    final interval = reviewInterval(level);
    return level <= 4
        ? _addActiveDuration(lastReviewed, interval)
        : lastReviewed.add(interval);
  }

  /// Cộng thêm [duration] vào [start], bỏ qua khoảng thời gian ngủ (00:00–06:00).
  static DateTime _addActiveDuration(DateTime start, Duration duration) {
    DateTime current = start;
    Duration remaining = duration;

    while (remaining.inMicroseconds > 0) {
      if (current.hour < 6) {
        current = DateTime(
            current.year, current.month, current.day, 6, 0, 0);
      } else {
        final nextMidnight = DateTime(
            current.year, current.month, current.day + 1, 0, 0, 0);
        final timeToMidnight = nextMidnight.difference(current);

        if (remaining <= timeToMidnight) {
          current = current.add(remaining);
          remaining = Duration.zero;
        } else {
          current = nextMidnight;
          remaining -= timeToMidnight;
        }
      }
    }
    return current;
  }
}
