import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/page/daily_quest/daily_quest_cubit.dart';
import 'package:test_abc/page/daily_quest/data/daily_quest_repository.dart';
import 'package:test_abc/page/daily_quest/data/quest_local_data_source.dart';
import 'package:test_abc/page/daily_quest/models/daily_quest_model.dart';
import 'package:test_abc/service/active_time_tracker.dart';
import 'package:test_abc/service/mission_service.dart';
import 'package:test_abc/generated/l10n.dart';

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
  // Cubit messages are localized, so the strings have to be loaded.
  setUpAll(() async {
    await S.load(const Locale('vi'));
  });

  final dayOneEvening = DateTime(2026, 9, 5, 22, 0);
  final dayTwoNight = DateTime(2026, 9, 6, 0, 10);

  late FakeQuestLocalDataSource dataSource;
  late DailyQuestRepository repository;
  late MissionService missionService;
  late ActiveTimeTracker tracker;
  late DateTime now;
  late int streakCompletions;
  late DailyQuestCubit cubit;

  DailyQuestModel defaultQuest() =>
      cubit.state.quests.firstWhere((q) => q.isDefault);

  Future<void> completeAllQuests() async {
    for (final quest in List.of(cubit.state.quests)) {
      await cubit.completeQuest(quest.id);
    }
  }

  /// One minute of active use, ticked second by second.
  Future<void> useAppForOneMinute() async {
    for (var i = 0; i < 60; i++) {
      final tickTime = now.add(Duration(seconds: i));
      tracker.recordActivity(tickTime);
      await cubit.onActivityTick(now: tickTime);
    }
  }

  setUp(() async {
    dataSource = FakeQuestLocalDataSource();
    repository = DailyQuestRepository(dataSource);
    missionService = MissionService(repository);
    now = dayOneEvening;
    tracker = ActiveTimeTracker(initialTime: now);
    streakCompletions = 0;
    cubit = DailyQuestCubit(
      missionService,
      activeTracker: tracker,
      clock: () => now,
      onStreakCompleted: () async => streakCompletions++,
    );
    addTearDown(cubit.close);
    await cubit.initData();
  });

  group('same day', () {
    test('refreshIfNewDay keeps the quests and their progress', () async {
      final quest = cubit.state.quests.firstWhere((q) => !q.isDefault);
      await cubit.onProgressByType(quest.type);
      now = DateTime(2026, 9, 5, 23, 59, 59);

      expect(await cubit.refreshIfNewDay(), isFalse);

      expect(
        cubit.state.quests.firstWhere((q) => q.id == quest.id).currentValue,
        1,
      );
    });
  });

  group('after midnight', () {
    test('finished quests are replaced by a fresh set', () async {
      await completeAllQuests();
      expect(cubit.state.allCompleted, isTrue);
      now = dayTwoNight;

      expect(await cubit.refreshIfNewDay(), isTrue);

      expect(cubit.state.loadStatus, LOADSTATUS.SUCCESS);
      expect(cubit.state.quests.length, 3);
      expect(cubit.state.completedCount, 0);
      expect(cubit.state.quests.every((q) => q.currentValue == 0), isTrue);
    });

    test('finishing the quests again counts for the new day', () async {
      await completeAllQuests();
      expect(streakCompletions, 1);
      now = dayTwoNight;

      await cubit.refreshIfNewDay();
      await completeAllQuests();

      expect(streakCompletions, 2);
    });

    test('half-done quests do not carry their progress over', () async {
      final quest = cubit.state.quests.firstWhere((q) => !q.isDefault);
      await cubit.onProgressByType(quest.type);
      await useAppForOneMinute();
      expect(defaultQuest().currentValue, 1);
      now = dayTwoNight;

      await cubit.refreshIfNewDay();

      expect(cubit.state.quests.every((q) => q.currentValue == 0), isTrue);
      expect(tracker.activeSeconds, 0);
    });

    test('active time of the new day starts from zero', () async {
      await useAppForOneMinute();
      now = dayTwoNight;
      await cubit.refreshIfNewDay();

      // 59 active seconds on the new day are not yet a full minute.
      for (var i = 0; i < 59; i++) {
        final tickTime = now.add(Duration(seconds: i));
        tracker.recordActivity(tickTime);
        await cubit.onActivityTick(now: tickTime);
      }

      expect(defaultQuest().currentValue, 0);
    });

    test('an action is counted on the quests of the new day', () async {
      await completeAllQuests();
      now = dayTwoNight;

      // No explicit refresh: the progress call itself notices the new day.
      await cubit.onProgressByType(QuestType.feedQuiz);

      expect(cubit.state.allCompleted, isFalse);
      expect(streakCompletions, 1);
      final feedQuests =
          cubit.state.quests.where((q) => q.type == QuestType.feedQuiz);
      expect(feedQuests.every((q) => q.currentValue == 1), isTrue);
      final otherQuests =
          cubit.state.quests.where((q) => q.type != QuestType.feedQuiz);
      expect(otherQuests.every((q) => q.currentValue == 0), isTrue);
    });

    test('a value computed for an old quest is dropped', () async {
      final oldDefault = defaultQuest();
      now = dayTwoNight;

      await cubit.updateProgress(oldDefault.id, oldDefault.targetValue);

      expect(defaultQuest().currentValue, 0);
      expect(streakCompletions, 0);
    });

    test('the activity tick switches to the new day', () async {
      await completeAllQuests();
      now = dayTwoNight;

      await cubit.onActivityTick(now: now);

      expect(cubit.state.completedCount, 0);
    });

    test('touching the screen switches to the new day', () async {
      await completeAllQuests();
      now = dayTwoNight;

      cubit.recordUserActivity(now);
      // Joins the reload started by the touch.
      expect(await cubit.refreshIfNewDay(), isTrue);

      expect(cubit.state.completedCount, 0);
    });

    test('new quests are stored under the new day', () async {
      await completeAllQuests();
      now = dayTwoNight;
      await cubit.refreshIfNewDay();

      final stored = await repository.loadTodayQuests(now: dayTwoNight);

      expect(stored, isNotNull);
      expect(stored?.every((q) => q.currentValue == 0), isTrue);
    });
  });

  group('storage', () {
    test('quests saved for an earlier day are not loaded as today\'s',
        () async {
      await completeAllQuests();

      expect(await repository.loadTodayQuests(now: dayOneEvening), isNotNull);
      expect(await repository.loadTodayQuests(now: dayTwoNight), isNull);
    });

    test('progress saved after midnight keeps the day of its quests',
        () async {
      // The old bug: yesterday's quests updated after midnight were written
      // back with today's date and then loaded as today's quests.
      final yesterdaysQuests = cubit.state.quests;

      final update = await missionService.completeQuest(
        yesterdaysQuests,
        yesterdaysQuests.first.id,
        questDay: dayOneEvening,
      );
      expect(update.success, isTrue);

      final today = await missionService.getTodayQuests(now: dayTwoNight);
      expect(today.data?.every((q) => q.currentValue == 0), isTrue);
    });
  });
}
