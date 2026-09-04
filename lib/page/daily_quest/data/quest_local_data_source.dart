import 'package:shared_preferences/shared_preferences.dart';

/// ─── INTERFACE (CONTRACT) ───────────────────────────────────────────
/// ĐIỂM PHỎNG VẤN - Dependency Inversion Principle:
/// Q: "Tại sao tạo interface cho việc đọc/ghi 2 cái key?"
/// A: 3 lý do:
///   1. TESTABILITY — Test không cần mock SharedPreferences,
///      chỉ cần FakeDataSource implement interface này.
///   2. SWAPPABLE — Muốn đổi sang Hive/SQLite? Tạo implement mới,
///      Repository không cần sửa 1 dòng nào.
///   3. SEPARATION — Repository biết "CẦN GÌ" (interface),
///      không biết "LÀM SAO" (SharedPreferences).
abstract class QuestLocalDataSource {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> remove(String key);
}

/// ─── IMPLEMENTATION ─────────────────────────────────────────────────
/// Đây là implementation cụ thể dùng SharedPreferences.
/// Chỉ class này biết SharedPreferences tồn tại.
class SharedPrefsQuestDataSource implements QuestLocalDataSource {
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
