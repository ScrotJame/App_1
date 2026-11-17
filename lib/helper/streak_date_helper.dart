/// Days on which the user finished every daily quest.
///
/// They are kept in SharedPreferences under [prefKey] as `yyyy-MM-dd` strings
/// and are the source of truth for the streak: `currentStreak`,
/// `longestStreak` and `lastActiveDate` on the user row are derived from them.
class StreakDateHelper {
  StreakDateHelper._();

  static const String prefKey = 'streak_marked_dates';

  static final RegExp _keyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The calendar day [days] before [day]. Works on the date fields rather
  /// than subtracting 24 hours, so a daylight-saving change never skips a day.
  static DateTime daysBefore(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day - days);

  /// Parses a `yyyy-MM-dd` key. Returns null for anything else, including
  /// dates that do not exist such as `2026-02-31`.
  static DateTime? tryParseKey(String key) {
    final match = _keyPattern.firstMatch(key);
    if (match == null) return null;
    final date = DateTime(
      int.parse(match.group(1) ?? ''),
      int.parse(match.group(2) ?? ''),
      int.parse(match.group(3) ?? ''),
    );
    return keyOf(date) == key ? date : null;
  }

  /// Keys of the [length] consecutive days that end on [lastDay].
  static Set<String> runEndingOn(DateTime lastDay, int length) {
    final end = dateOnly(lastDay);
    return {for (var i = 0; i < length; i++) keyOf(daysBefore(end, i))};
  }
}
