import '../page/daily_quest/data/daily_quest_repository.dart';
import '../page/daily_quest/models/daily_quest_model.dart';
import '../page/daily_quest/models/mission_pool.dart';
import '../ultis/error_utils.dart';

// ═══════════════════════════════════════════════════════════════════════
// MISSION SERVICE — Application Service (Orchestrator)
// ═══════════════════════════════════════════════════════════════════════
//
// ĐÂY LÀ FILE QUAN TRỌNG NHẤT CỦA MODULE DAILY QUEST.
//
// ── CÂU HỎI PHỎNG VẤN THƯỜNG GẶP ──────────────────────────────────
//
// Q1: "MissionService khác gì Cubit?"
// A:  Cubit quản lý UI STATE (emit, rebuild widget).
//     Service xử lý BUSINESS LOGIC (tạo quest, tính streak, xử lý lỗi).
//     Cubit GỌI Service, Service KHÔNG BIẾT Cubit tồn tại.
//
// Q2: "MissionService khác gì Repository?"
// A:  Repository CHỈ đọc/ghi data (I/O thuần).
//     Service ĐIỀU PHỐI: gọi Repo, gọi MissionPool, tính toán logic,
//     rồi trả về Result cho Cubit.
//
// Q3: "Tại sao không để Cubit gọi thẳng Repository?"
// A:  Vì Cubit sẽ phình to, khó test. Service tách logic ra,
//     mock 1 Service khi test Cubit là đủ.
//
// Q4: "Service có phải Singleton không?"
// A:  KHÔNG. Service được inject qua DI (RepositoryProvider trong app.dart).
//     Singleton = global state = khó test. DI = dễ test, dễ swap.
//
// ═══════════════════════════════════════════════════════════════════════

class MissionService {
  final DailyQuestRepository _repository;

  MissionService(this._repository);

  // ─── 1. GET TODAY QUESTS ─────────────────────────────────────────
  // Use case: App khởi động → cần hiển thị quest hôm nay.
  // Logic:
  //   - Có cache hôm nay? → trả về cache
  //   - Không có (ngày mới)? → generate 3 quest mới, lưu, trả về
  //
  // Return QuestResult thay vì throw exception:
  //   - QuestResult.ok(data) khi thành công
  //   - QuestResult.fail(error) khi lỗi
  // → Cubit không cần try/catch, code sạch hơn.
  // ─────────────────────────────────────────────────────────────────

  Future<QuestResult<List<DailyQuestModel>>> getTodayQuests() async {
    try {
      // Bước 1: Hỏi Repository "có data hôm nay không?"
      final cached = await _repository.loadTodayQuests();

      if (cached != null) {
        // Có → trả về ngay, không tạo mới
        return QuestResult.ok(cached);
      }

      // Không có → ngày mới, cần generate
      final quests = await _generateAndSave();
      return QuestResult.ok(quests);
    } catch (e) {
      // Lỗi xảy ra → bọc vào QuestResult.fail
      // Cubit nhận được error message thân thiện, không phải stack trace
      return QuestResult.fail(ErrorUtils.networkErrorToMessage(e));
    }
  }

  /// Generate 3 quest: 1 default + 2 random, rồi lưu qua Repository.
  Future<List<DailyQuestModel>> _generateAndSave() async {
    final today = DateTime.now();
    final randomQuests = MissionPool.pickDaily(today);
    final allQuests = [MissionPool.defaultMission, ...randomQuests];
    await _repository.saveTodayQuests(allQuests);
    return allQuests;
  }

  // ─── 2. UPDATE PROGRESS ─────────────────────────────────────────
  // Use case: User học 3 từ → quest "Học 5 từ" cập nhật 0→3.
  //
  // Đây là method PHỨC TẠP NHẤT — cần hiểu rõ:
  //
  // Input:  currentQuests (state hiện tại), questId, newValue
  // Output: QuestUpdateResult chứa:
  //   - quests: danh sách đã cập nhật
  //   - newlyCompletedIds: quest nào VỪA hoàn thành (để UI animate)
  //   - shouldMarkStreak: có nên gọi StreakCubit.markToday() không
  //
  // CÂU HỎI PHỎNG VẤN:
  // Q: "Tại sao Service return shouldMarkStreak thay vì tự gọi Streak?"
  // A: Vì Service KHÔNG BIẾT StreakCubit tồn tại (nó ở tầng UI).
  //    Service chỉ BÁO HIỆU: "hey, tất cả quest xong rồi đấy".
  //    Cubit nhận tín hiệu → tự quyết định gọi StreakCubit.
  //    → Đây là Separation of Concerns.
  // ─────────────────────────────────────────────────────────────────

  Future<QuestResult<QuestUpdateResult>> updateProgress(
    List<DailyQuestModel> currentQuests,
    String questId,
    int newValue,
  ) async {
    try {
      // Ghi nhớ trạng thái TRƯỚC khi update
      final wasAllCompleted = _areAllCompleted(currentQuests);
      final List<String> newlyCompletedIds = [];

      // Map qua list: tìm quest cần update, tạo bản copy mới
      final updated = currentQuests.map((q) {
        if (q.id == questId) {
          final wasCompleted = q.isCompleted;
          final updatedQuest = q.copyWith(currentValue: newValue);

          // Detect: quest này VỪA chuyển từ chưa xong → xong
          if (!wasCompleted && updatedQuest.isCompleted) {
            newlyCompletedIds.add(q.id);
          }
          return updatedQuest;
        }
        return q;
      }).toList();

      // Persist xuống storage
      await _repository.saveTodayQuests(updated);

      // Tính toán: có nên mark streak không?
      // Điều kiện: TRƯỚC chưa xong hết + SAU xong hết = vừa hoàn thành
      final isNowAllCompleted = _areAllCompleted(updated);
      final shouldMarkStreak = !wasAllCompleted && isNowAllCompleted;

      return QuestResult.ok(QuestUpdateResult(
        quests: updated,
        newlyCompletedIds: newlyCompletedIds,
        shouldMarkStreak: shouldMarkStreak,
      ));
    } catch (e) {
      return QuestResult.fail(ErrorUtils.networkErrorToMessage(e));
    }
  }

  // ─── 3. TIMER TICK — ĐẾM THỜI GIAN TRONG APP ────────────────────
  // Use case: User mở app → Timer chạy mỗi phút → +1 progress
  //           Khi đạt 5 phút → quest mặc định tự hoàn thành.
  //
  // Gọi bởi: Cubit's periodic Timer (1 phút / tick)
  // ─────────────────────────────────────────────────────────────────

  Future<QuestResult<QuestUpdateResult>> onTimerTick(
    List<DailyQuestModel> currentQuests,
  ) async {
    // Tìm quest mặc định chưa hoàn thành
    final defaultQuest = currentQuests
        .where((q) => q.isDefault && !q.isCompleted)
        .toList();

    if (defaultQuest.isEmpty) {
      // Đã complete rồi hoặc không có default quest → không làm gì
      return QuestResult.ok(QuestUpdateResult(quests: currentQuests));
    }

    // +1 phút vào progress
    final quest = defaultQuest.first;
    final newValue = (quest.currentValue + 1).clamp(0, quest.targetValue);

    return updateProgress(currentQuests, quest.id, newValue);
  }

  // ─── 4. COMPLETE QUEST (SHORTCUT) ───────────────────────────────
  // Dùng khi biết chắc quest đã hoàn thành (ví dụ: quiz xong).
  // ─────────────────────────────────────────────────────────────────

  Future<QuestResult<QuestUpdateResult>> completeQuest(
    List<DailyQuestModel> currentQuests,
    String questId,
  ) async {
    final quest = currentQuests.where((q) => q.id == questId).toList();
    if (quest.isEmpty) {
      return QuestResult.fail('Quest không tồn tại: $questId');
    }
    return updateProgress(currentQuests, questId, quest.first.targetValue);
  }

  // ─── PRIVATE HELPERS ────────────────────────────────────────────

  bool _areAllCompleted(List<DailyQuestModel> quests) =>
      quests.isNotEmpty && quests.every((q) => q.isCompleted);
}

// ═══════════════════════════════════════════════════════════════════════
// RESULT TYPES
// ═══════════════════════════════════════════════════════════════════════
//
// Pattern giống ImportResult/ExportResult trong backup_entity.dart
// của dự án. Giữ nhất quán.
//
// CÂU HỎI PHỎNG VẤN:
// Q: "Tại sao dùng Result type thay vì throw Exception?"
// A: 3 lý do:
//   1. EXPLICIT — Nhìn return type biết ngay method có thể fail
//   2. NO TRY/CATCH — Caller xử lý bằng if/else, code phẳng hơn
//   3. COMPOSABLE — Có thể chain nhiều Result operations
//
// Q: "Tại sao không dùng package dartz/fpdart (Either type)?"
// A: Overkill cho module nhỏ. Custom Result class đủ dùng
//    và giữ nhất quán với pattern đã có trong dự án.
// ═══════════════════════════════════════════════════════════════════════

/// Result type generic — dùng cho mọi operation của MissionService.
class QuestResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const QuestResult.ok(this.data)
      : success = true,
        error = null;

  const QuestResult.fail(this.error)
      : success = false,
        data = null;
}

/// Kết quả chi tiết sau khi update quest.
/// Chứa đủ thông tin để Cubit quyết định hành động tiếp theo.
class QuestUpdateResult {
  /// Danh sách quest đã cập nhật (toàn bộ, không chỉ quest thay đổi).
  final List<DailyQuestModel> quests;

  /// ID các quest VỪA chuyển sang completed trong lần update này.
  /// → Cubit dùng để trigger animation "hoàn thành".
  final List<String> newlyCompletedIds;

  /// True khi TẤT CẢ quest vừa hoàn thành (transition point).
  /// → Cubit dùng để gọi StreakCubit.markToday().
  final bool shouldMarkStreak;

  const QuestUpdateResult({
    required this.quests,
    this.newlyCompletedIds = const [],
    this.shouldMarkStreak = false,
  });
}