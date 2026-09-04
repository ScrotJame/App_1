import 'dart:convert';

/// ─── WHY ENUM? ──────────────────────────────────────────────────────
/// Enum giúp type-safe: compiler sẽ báo lỗi nếu bạn quên handle 1 case.
/// Trong phỏng vấn: "Tại sao dùng enum thay vì String?"
/// → Vì String có thể typo ('learnWord' vs 'learnWords'), enum thì không.
enum QuestType {
  learnWords,
  reviewWords,
  completeQuiz,
  studyMinutes,
  loginDaily,
}

/// ─── DAILY QUEST MODEL ──────────────────────────────────────────────
/// Đây là Domain Model — chạy xuyên suốt tất cả các tầng.
///
/// QUAN TRỌNG cho phỏng vấn:
/// - Model này là IMMUTABLE (tất cả field đều final)
/// - Muốn thay đổi → tạo bản copy mới qua copyWith()
/// - Không có side effect, không gọi API, không biết UI
class DailyQuestModel {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final String icon;
  final int targetValue;
  final int currentValue;
  final bool isDefault;
  final int rewardGems;

  /// Computed properties — logic thuần túy, không side effect
  bool get isCompleted => currentValue >= targetValue;

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  const DailyQuestModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    this.currentValue = 0,
    this.isDefault = false,
    this.rewardGems = 10,
  });

  /// ─── COPY WITH ──────────────────────────────────────────────
  /// Pattern bắt buộc cho immutable object.
  /// Cubit gọi: quest.copyWith(currentValue: 5)
  /// → Tạo quest MỚI với currentValue = 5, giữ nguyên các field khác.
  DailyQuestModel copyWith({int? currentValue}) {
    return DailyQuestModel(
      id: id,
      type: type,
      title: title,
      description: description,
      icon: icon,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      isDefault: isDefault,
      rewardGems: rewardGems,
    );
  }

  /// ─── SERIALIZATION ──────────────────────────────────────────
  /// Tại sao tự viết mà không dùng json_serializable?
  /// → Module nhỏ (1 model), thêm code-gen = overkill.
  /// → Trong phỏng vấn: "Khi nào dùng json_serializable?"
  ///   → Khi có 5+ model hoặc model lồng nhau phức tạp.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name, // enum.name → 'learnWords' (String)
        'title': title,
        'description': description,
        'icon': icon,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'isDefault': isDefault,
        'rewardGems': rewardGems,
      };

  factory DailyQuestModel.fromJson(Map<String, dynamic> json) {
    return DailyQuestModel(
      id: json['id'] as String,
      type: QuestType.values.byName(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      rewardGems: json['rewardGems'] as int? ?? 10,
    );
  }

  /// Helper: encode/decode list cho SharedPreferences
  static String encodeList(List<DailyQuestModel> quests) =>
      jsonEncode(quests.map((q) => q.toJson()).toList());

  static List<DailyQuestModel> decodeList(String jsonStr) {
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded
        .map((e) => DailyQuestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
