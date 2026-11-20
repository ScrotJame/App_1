import 'package:shared_preferences/shared_preferences.dart';

/// Storage of the daily review. Same shape as QuestLocalDataSource, so tests
/// can use an in-memory fake.
abstract class DailyReviewLocalDataSource {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> remove(String key);
}

class SharedPrefsDailyReviewDataSource implements DailyReviewLocalDataSource {
  @override
  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
