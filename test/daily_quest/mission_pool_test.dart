import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/daily_quest/models/daily_quest_model.dart';
import 'package:test_abc/page/daily_quest/models/mission_pool.dart';

void main() {
  group('MissionPool Tests', () {
    test('default mission should be 5 minutes active usage', () {
      final defaultMission = MissionPool.defaultMission;
      expect(defaultMission.isDefault, isTrue);
      expect(defaultMission.targetValue, 5);
      expect(defaultMission.type, QuestType.loginDaily);
      expect(defaultMission.title, anyOf(contains('Sử dụng app'), contains('Khởi động')));
    });

    test('pickDaily should always return exactly 2 distinct missions', () {
      final date = DateTime(2026, 9, 5);
      final picked = MissionPool.pickDaily(date);

      expect(picked.length, 2);
      expect(picked[0].id, isNot(equals(picked[1].id)));
      expect(picked[0].isDefault, isFalse);
      expect(picked[1].isDefault, isFalse);
    });

    test('pickDaily should be deterministic for the same date', () {
      final date = DateTime(2026, 9, 5);
      final run1 = MissionPool.pickDaily(date);
      final run2 = MissionPool.pickDaily(date);

      expect(run1[0].id, equals(run2[0].id));
      expect(run1[1].id, equals(run2[1].id));
    });

    test('pool contains tasks for learning words, test quiz, and training feed', () {
      final date1 = DateTime(2026, 9, 5);
      final date2 = DateTime(2026, 9, 6);
      final date3 = DateTime(2026, 9, 7);

      final allTypes = <QuestType>{};
      for (final d in [date1, date2, date3]) {
        final quests = MissionPool.pickDaily(d);
        for (final q in quests) {
          allTypes.add(q.type);
        }
      }

      // Should include at least learnWords, completeQuiz, or feedQuiz
      expect(allTypes.contains(QuestType.learnWords) ||
             allTypes.contains(QuestType.completeQuiz) ||
             allTypes.contains(QuestType.feedQuiz), isTrue);
    });
  });
}
