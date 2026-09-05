import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/page/daily_quest/daily_quest_cubit.dart';
import 'package:test_abc/page/daily_quest/data/daily_quest_repository.dart';
import 'package:test_abc/page/daily_quest/data/quest_local_data_source.dart';
import 'package:test_abc/service/active_time_tracker.dart';
import 'package:test_abc/service/mission_service.dart';

class FakeQuestLocalDataSource implements QuestLocalDataSource {
  final Map<String, String> storage = {};

  @override
  Future<String?> readString(String key) async => storage[key];

  @override
  Future<void> writeString(String key, String value) async {
    storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    storage.remove(key);
  }
}

void main() {
  group('DailyQuestCubit Tests', () {
    late FakeQuestLocalDataSource fakeDataSource;
    late DailyQuestRepository repository;
    late MissionService missionService;
    late ActiveTimeTracker activeTracker;

    setUp(() {
      fakeDataSource = FakeQuestLocalDataSource();
      repository = DailyQuestRepository(fakeDataSource);
      missionService = MissionService(repository);
      activeTracker = ActiveTimeTracker(
        initialTime: DateTime(2026, 9, 5, 10, 0, 0),
        idleThreshold: const Duration(seconds: 30),
      );
    });

    test('initData should load 3 quests with 1 default mission', () async {
      final cubit = DailyQuestCubit(
        missionService,
        activeTracker: activeTracker,
      );

      await cubit.initData();

      expect(cubit.state.loadStatus, LOADSTATUS.SUCCESS);
      expect(cubit.state.quests.length, 3);
      expect(cubit.state.quests.where((q) => q.isDefault).length, 1);
      expect(cubit.state.allCompleted, isFalse);

      await cubit.close();
    });

    test('active time tracker tick updates default quest and skips when idle', () async {
      final cubit = DailyQuestCubit(
        missionService,
        activeTracker: activeTracker,
      );
      await cubit.initData();

      final defaultQuestId = cubit.state.quests.firstWhere((q) => q.isDefault).id;
      final baseTime = DateTime(2026, 9, 5, 10, 0, 0);

      // Active tick 60 times (60 seconds)
      for (int i = 1; i <= 60; i++) {
        activeTracker.recordActivity(baseTime.add(Duration(seconds: i)));
        await cubit.onActivityTick(now: baseTime.add(Duration(seconds: i)), stepSeconds: 1);
      }

      // Default quest should have progress = 1 minute (currentValue = 1)
      final updatedQuest = cubit.state.quests.firstWhere((q) => q.id == defaultQuestId);
      expect(updatedQuest.currentValue, 1);

      // Idle for 40 seconds (no recordActivity) -> should NOT increment
      final idleTime = baseTime.add(const Duration(seconds: 120));
      await cubit.onActivityTick(now: idleTime, stepSeconds: 10);
      final idleQuest = cubit.state.quests.firstWhere((q) => q.id == defaultQuestId);
      expect(idleQuest.currentValue, 1);

      await cubit.close();
    });

    test('should trigger onStreakCompleted callback when all 3 quests are completed', () async {
      int streakTriggerCount = 0;

      final cubit = DailyQuestCubit(
        missionService,
        activeTracker: activeTracker,
        onStreakCompleted: () async {
          streakTriggerCount++;
        },
      );
      await cubit.initData();

      final quests = cubit.state.quests;
      expect(quests.length, 3);

      // Complete quest 1
      await cubit.completeQuest(quests[0].id);
      expect(streakTriggerCount, 0);
      expect(cubit.state.allCompleted, isFalse);

      // Complete quest 2
      await cubit.completeQuest(quests[1].id);
      expect(streakTriggerCount, 0);
      expect(cubit.state.allCompleted, isFalse);

      // Complete quest 3 -> all completed
      await cubit.completeQuest(quests[2].id);
      expect(cubit.state.allCompleted, isTrue);
      expect(streakTriggerCount, 1);

      // Completing again or updating already completed should not trigger streak callback again
      await cubit.completeQuest(quests[2].id);
      expect(streakTriggerCount, 1);

      await cubit.close();
    });

    test('onProgressByType should increment matching quest by type', () async {
      final cubit = DailyQuestCubit(
        missionService,
        activeTracker: activeTracker,
      );
      await cubit.initData();

      // Find a random quest
      final nonDefault = cubit.state.quests.firstWhere((q) => !q.isDefault);
      final initialVal = nonDefault.currentValue;

      await cubit.onProgressByType(nonDefault.type, increment: 2);

      final updated = cubit.state.quests.firstWhere((q) => q.id == nonDefault.id);
      expect(updated.currentValue, initialVal + 2);

      await cubit.close();
    });
  });
}
