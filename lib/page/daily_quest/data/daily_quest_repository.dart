import '../models/daily_quest_model.dart';
import 'quest_local_data_source.dart';

/// ─── REPOSITORY ─────────────────────────────────────────────────────
/// CHỈ làm I/O: đọc/ghi quest data qua interface QuestLocalDataSource.
///
/// ĐIỂM PHỎNG VẤN:
/// Q: "Repository vs DataSource khác gì?"
/// A: DataSource biết HOW (SharedPrefs, Hive, API...)
///    Repository biết WHAT (serialize quest, check ngày, format key)
///    Repository gọi DataSource, không ngược lại.
class DailyQuestRepository {
  final QuestLocalDataSource _dataSource;

  static const _prefKey = 'daily_quest_data';
  static const _prefDateKey = 'daily_quest_date';

  DailyQuestRepository(this._dataSource);

  /// Load quest đã lưu — return null nếu không có hoặc hết hạn (ngày cũ).
  ///
  /// Logic "không lưu lịch sử" nằm ở đây:
  /// Nếu savedDate ≠ today → data cũ bị xóa, return null.
  Future<List<DailyQuestModel>?> loadTodayQuests({DateTime? now}) async {
    final savedDate = await _dataSource.readString(_prefDateKey);
    final today = _dayKey(now ?? DateTime.now());

    if (savedDate != today) {
      // Ngày cũ → xóa sạch, không giữ lịch sử
      await _dataSource.remove(_prefKey);
      await _dataSource.remove(_prefDateKey);
      return null;
    }

    final jsonStr = await _dataSource.readString(_prefKey);
    if (jsonStr == null) return null;

    return DailyQuestModel.decodeList(jsonStr);
  }

  /// Lưu quest kèm ngày mà chúng thuộc về.
  ///
  /// [day] là ngày quest được tạo ra, KHÔNG phải thời điểm lưu. Nếu app còn
  /// mở qua nửa đêm và lưu tiến độ của quest hôm qua, dữ liệu vẫn mang ngày
  /// hôm qua nên lần load sau sẽ bỏ đi thay vì coi là quest của hôm nay.
  Future<void> saveTodayQuests(
    List<DailyQuestModel> quests, {
    DateTime? day,
  }) async {
    final jsonStr = DailyQuestModel.encodeList(quests);
    await _dataSource.writeString(_prefKey, jsonStr);
    await _dataSource.writeString(_prefDateKey, _dayKey(day ?? DateTime.now()));
  }

  /// Clear tất cả quest data.
  Future<void> clearQuests() async {
    await _dataSource.remove(_prefKey);
    await _dataSource.remove(_prefDateKey);
  }

  /// Format ngày: '2026-07-20'
  String _dayKey(DateTime now) {
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
