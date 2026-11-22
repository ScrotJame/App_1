import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../helper/streak_date_helper.dart';

/// The words that levelled up through Test today, so each one levels up at
/// most once a day. Not backed up: it only matters until midnight.
class TestDailyLevelStore {
  static String keyFor(String userKey) => 'test_level_up_today_$userKey';

  /// Empty on another day, on broken data, or when reading fails.
  Future<Set<int>> leveledToday(String userKey, DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(userKey));
      if (raw == null) return <int>{};
      final json = jsonDecode(raw);
      if (json is! Map || json['date'] != StreakDateHelper.keyOf(now)) {
        return <int>{};
      }
      final ids = json['wordIds'];
      if (ids is! List) return <int>{};
      return ids.whereType<int>().toSet();
    } catch (_) {
      return <int>{};
    }
  }

  /// Written right after each level-up, so a crash mid-test keeps the marks.
  Future<void> markLeveled(String userKey, int wordId, DateTime now) async {
    try {
      final ids = await leveledToday(userKey, now)
        ..add(wordId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        keyFor(userKey),
        jsonEncode({
          'date': StreakDateHelper.keyOf(now),
          'wordIds': ids.toList()..sort(),
        }),
      );
    } catch (_) {
      // Losing a mark only lets the word level up once more today.
    }
  }
}
