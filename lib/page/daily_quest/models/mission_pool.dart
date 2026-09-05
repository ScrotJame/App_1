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
  /// Auto-complete khi user ở trong app đủ 5 phút (có tương tác).
  static DailyQuestModel get defaultMission => const DailyQuestModel(
        id: 'default_active_time',
        type: QuestType.loginDaily,
        title: 'Sử dụng app 5 phút',
        description: 'Tương tác trong ứng dụng 5 phút',
        icon: '⏱️',
        targetValue: 5,
        isDefault: true,
        rewardGems: 5,
      );

  /// ─── POOL RANDOM ───────────────────────────────────────────
  /// Mỗi entry là 1 factory function trả về instance mới.
  /// Bốc ngẫu nhiên 2 nhiệm vụ từ các nhóm: Học từ mới, Bài kiểm tra, Training Feed.
  static final List<DailyQuestModel Function()> _randomPool = [
    () => const DailyQuestModel(
          id: 'learn_5',
          type: QuestType.learnWords,
          title: 'Học 5 từ mới',
          description: 'Học thêm 5 từ vựng mới',
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
          id: 'quiz_1',
          type: QuestType.completeQuiz,
          title: 'Hoàn thành 1 bài kiểm tra',
          description: 'Vượt qua 1 bài kiểm tra từ vựng',
          icon: '🎯',
          targetValue: 1,
          rewardGems: 15,
        ),
    () => const DailyQuestModel(
          id: 'feed_5',
          type: QuestType.feedQuiz,
          title: 'Luyện 5 câu trên Feed',
          description: 'Trả lời 5 câu hỏi nhanh trên Feed',
          icon: '🔥',
          targetValue: 5,
          rewardGems: 10,
        ),
    () => const DailyQuestModel(
          id: 'feed_10',
          type: QuestType.feedQuiz,
          title: 'Luyện 10 câu trên Feed',
          description: 'Trả lời 10 câu hỏi nhanh trên Feed',
          icon: '⚡',
          targetValue: 10,
          rewardGems: 15,
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
