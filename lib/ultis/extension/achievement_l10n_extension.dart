import 'package:test_abc/generated/l10n.dart';

extension AchievementL10n on S {
  // Map ánh xạ key trong database tới thuộc tính trong S (L10n)
  Map<String, String> get achievementMap => {
    'achievement_first_word_title': achievement_first_word_title,
    'achievement_first_word_desc': achievement_first_word_desc,
    'achievement_total_10_title': achievement_total_10_title,
    'achievement_total_10_desc': achievement_total_10_desc,
    'achievement_total_50_title': achievement_total_50_title,
    'achievement_total_50_desc': achievement_total_50_desc,
    'achievement_total_100_title': achievement_total_100_title,
    'achievement_total_100_desc': achievement_total_100_desc,
    'achievement_total_500_title': achievement_total_500_title,
    'achievement_total_500_desc': achievement_total_500_desc,
    'achievement_total_1000_title': achievement_total_1000_title,
    'achievement_total_1000_desc': achievement_total_1000_desc,
    'achievement_streak_3_title': achievement_streak_3_title,
    'achievement_streak_3_desc': achievement_streak_3_desc,
    'achievement_streak_7_title': achievement_streak_7_title,
    'achievement_streak_7_desc': achievement_streak_7_desc,
    'achievement_streak_30_title': achievement_streak_30_title,
    'achievement_streak_30_desc': achievement_streak_30_desc,
    'achievement_streak_100_title': achievement_streak_100_title,
    'achievement_streak_100_desc': achievement_streak_100_desc,
    'achievement_complete_unit_title': achievement_complete_unit_title,
    'achievement_complete_unit_desc': achievement_complete_unit_desc,
    'achievement_complete_unit_5_title': achievement_complete_unit_5_title,
    'achievement_complete_unit_5_desc': achievement_complete_unit_5_desc,
    'achievement_night_owl_title': achievement_night_owl_title,
    'achievement_night_owl_desc': achievement_night_owl_desc,
  };

  String getLocalizedAchievement(String? key) {
    if (key == null || key.isEmpty) return "";
    final result = achievementMap[key];
    if (result == null) {
      print("CẢNH BÁO: Không tìm thấy key: $key trong map");
    }
    return result ?? key;
  }
}