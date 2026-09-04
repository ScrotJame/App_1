import 'dart:math';
import 'daily_quest_model.dart';

/// ─── MISSION POOL ───────────────────────────────────────────────────
/// Pool chứa tất cả nhiệm vụ có thể random.
///
/// ĐIỂM PHỎNG VẤN:
/// Q: "Tại sao dùng factory function `() => Model` thay vì `List<Model>`?"
/// A: Vì mỗi lần pick cần instance MỚI (currentValue = 0).
///    Nếu dùng `List<Model>`, tất cả reference cùng 1 object → sửa 1 cái
///    ảnh hưởng hết. Factory function tạo instance mới mỗi lần gọi.
class MissionPool {
  MissionPool._(); // private constructor — không ai tạo instance được

  /// ─── MISSION MẶC ĐỊNH ──────────────────────────────────────
  /// Auto-complete khi user ở trong app đủ 5 phút.
  /// Cubit dùng Timer periodic (1 phút/tick) để cập nhật progress.
  static DailyQuestModel get defaultMission => const DailyQuestModel(
        id: 'default_login',
        type: QuestType.loginDaily,
        title: 'Khởi động ngày mới',
        description: 'Ở trong ứng dụng 5 phút',
        icon: '☀️',
        targetValue: 5,
        isDefault: true,
        rewardGems: 5,
      );

  /// ─── POOL RANDOM ───────────────────────────────────────────
  /// Mỗi entry là 1 factory function trả về instance mới.
  static final List<DailyQuestModel Function()> _randomPool = [
    () => const DailyQuestModel(
          id: 'learn_5',
          type: QuestType.learnWords,
          title: 'Học 5 từ mới',
          description: 'Thêm 5 từ vựng mới vào kho từ',
          icon: '📚',
          targetValue: 5,
          rewardGems: 10,
        ),
    () => const DailyQuestModel(
          id: 'learn_10',
          type: QuestType.learnWords,
          title: 'Học 10 từ mới',
          description: 'Mở rộng vốn từ với 10 từ mới',
          icon: '📖',
          targetValue: 10,
          rewardGems: 15,
        ),
    () => const DailyQuestModel(
          id: 'review_5',
          type: QuestType.reviewWords,
          title: 'Ôn tập 5 từ',
          description: 'Củng cố trí nhớ với 5 từ đã học',
          icon: '🔄',
          targetValue: 5,
          rewardGems: 10,
        ),
    () => const DailyQuestModel(
          id: 'review_10',
          type: QuestType.reviewWords,
          title: 'Ôn tập 10 từ',
          description: 'Ôn luyện sâu với 10 từ cũ',
          icon: '🧠',
          targetValue: 10,
          rewardGems: 15,
        ),
    () => const DailyQuestModel(
          id: 'quiz_1',
          type: QuestType.completeQuiz,
          title: 'Hoàn thành 1 bài quiz',
          description: 'Thử sức với 1 bài kiểm tra',
          icon: '🎯',
          targetValue: 1,
          rewardGems: 15,
        ),
    () => const DailyQuestModel(
          id: 'study_10min',
          type: QuestType.studyMinutes,
          title: 'Học 10 phút',
          description: 'Dành 10 phút học tập liên tục',
          icon: '⏱️',
          targetValue: 10,
          rewardGems: 10,
        ),
  ];

  /// ─── DETERMINISTIC RANDOM ──────────────────────────────────
  /// ĐIỂM PHỎNG VẤN QUAN TRỌNG:
  /// Q: "Tại sao dùng seed = ngày?"
  /// A: Random(seed) là pseudo-random — cùng seed luôn ra cùng sequence.
  ///    Seed = ngày → cùng 1 ngày, dù mở app bao nhiêu lần, luôn ra
  ///    cùng 2 mission. Ngày mới → seed mới → mission mới.
  ///
  /// Q: "Nếu pool chỉ có 6 mission, sẽ bị trùng lặp không?"
  /// A: Shuffle rồi lấy 2 đầu → không bao giờ trùng nhau trong cùng ngày.
  ///    Nhưng có thể trùng với ngày hôm qua → chấp nhận được vì pool nhỏ.
  static List<DailyQuestModel> pickDaily(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);
    final shuffled = List.of(_randomPool)..shuffle(random);
    return [shuffled[0](), shuffled[1]()];
  }
}
