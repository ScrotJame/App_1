import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/daily_quest/daily_quest_cubit.dart';
import 'package:test_abc/page/daily_quest/data/daily_quest_repository.dart';
import 'package:test_abc/page/daily_quest/data/quest_local_data_source.dart';
import 'package:test_abc/page/daily_quest/models/daily_quest_model.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/service/active_time_tracker.dart';
import 'package:test_abc/service/mission_service.dart';
import 'package:test_abc/generated/l10n.dart';

import '../repository/backup_test_support.dart';

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

const _activeTimeQuest = DailyQuestModel(
  id: 'default_active_time',
  type: QuestType.loginDaily,
  title: 'Use the app',
  description: '',
  icon: '',
  targetValue: 5,
  isDefault: true,
  rewardGems: 5,
);

const _feedQuest = DailyQuestModel(
  id: 'feed_5',
  type: QuestType.feedQuiz,
  title: 'Feed',
  description: '',
  icon: '',
  targetValue: 5,
  rewardGems: 10,
);

const _quizQuest = DailyQuestModel(
  id: 'quiz_1',
  type: QuestType.completeQuiz,
  title: 'Quiz',
  description: '',
  icon: '',
  targetValue: 1,
  rewardGems: 15,
);

void main() {
  // Cubit messages are localized, so the strings have to be loaded.
  setUpAll(() async {
    await S.load(const Locale('vi'));
  });

  final today = DateTime(2026, 9, 5, 10);

  late DailyQuestRepository repository;
  late MissionService missionService;

  /// A cubit whose quests for today are the three quests above.
  Future<DailyQuestCubit> openCubit({
    Future<void> Function(int gems)? onQuestRewarded,
    Future<void> Function()? onStreakCompleted,
  }) async {
    final cubit = DailyQuestCubit(
      missionService,
      activeTracker: ActiveTimeTracker(initialTime: today),
      clock: () => today,
      onQuestRewarded: onQuestRewarded,
      onStreakCompleted: onStreakCompleted,
    );
    addTearDown(cubit.close);
    await cubit.initData();
    return cubit;
  }

  DailyQuestModel questOf(DailyQuestCubit cubit, String id) =>
      cubit.state.quests.firstWhere((q) => q.id == id);

  setUp(() async {
    repository = DailyQuestRepository(FakeQuestLocalDataSource());
    missionService = MissionService(repository);
    await repository.saveTodayQuests(
      const [_activeTimeQuest, _feedQuest, _quizQuest],
      day: today,
    );
  });

  group('reward callback', () {
    late List<int> payouts;
    late int streakCompletions;
    late DailyQuestCubit cubit;

    setUp(() async {
      payouts = [];
      streakCompletions = 0;
      cubit = await openCubit(
        onQuestRewarded: (gems) async => payouts.add(gems),
        onStreakCompleted: () async => streakCompletions++,
      );
    });

    test('completing a quest pays its gems', () async {
      await cubit.completeQuest(_quizQuest.id);

      expect(payouts, [15]);
    });

    test('progress below the target pays nothing', () async {
      await cubit.onProgressByType(QuestType.feedQuiz);
      await cubit.onProgressByType(QuestType.feedQuiz);

      expect(questOf(cubit, _feedQuest.id).currentValue, 2);
      expect(payouts, isEmpty);
    });

    test('reaching the target step by step pays once', () async {
      for (var i = 0; i < 7; i++) {
        await cubit.onProgressByType(QuestType.feedQuiz);
      }

      expect(questOf(cubit, _feedQuest.id).isCompleted, isTrue);
      expect(payouts, [10]);
    });

    test('a finished quest does not pay again', () async {
      await cubit.completeQuest(_quizQuest.id);

      await cubit.completeQuest(_quizQuest.id);
      await cubit.onProgressByType(QuestType.completeQuiz);
      await cubit.updateProgress(_quizQuest.id, 3);

      expect(payouts, [15]);
    });

    test('the same quest completed twice at once pays once', () async {
      await Future.wait([
        cubit.completeQuest(_quizQuest.id),
        cubit.completeQuest(_quizQuest.id),
      ]);

      expect(payouts, [15]);
    });

    test('actions reported at the same time are all counted', () async {
      await Future.wait([
        cubit.onProgressByType(QuestType.feedQuiz),
        cubit.onProgressByType(QuestType.feedQuiz),
        cubit.onProgressByType(QuestType.feedQuiz),
      ]);

      expect(questOf(cubit, _feedQuest.id).currentValue, 3);
    });

    test('the active-time quest pays when its minutes are reached', () async {
      await cubit.updateProgress(
        _activeTimeQuest.id,
        _activeTimeQuest.targetValue,
      );

      expect(payouts, [5]);
    });

    test('finishing every quest pays each reward and marks the streak',
        () async {
      await cubit.completeQuest(_activeTimeQuest.id);
      await cubit.completeQuest(_feedQuest.id);
      await cubit.completeQuest(_quizQuest.id);

      expect(payouts, [5, 10, 15]);
      expect(streakCompletions, 1);
    });

    test('a reopened app does not pay finished quests again', () async {
      await cubit.completeQuest(_quizQuest.id);

      final reopened = await openCubit(
        onQuestRewarded: (gems) async => payouts.add(gems),
      );
      await reopened.completeQuest(_quizQuest.id);

      expect(reopened.state.completedCount, 1);
      expect(payouts, [15]);
    });
  });

  group('failed payout', () {
    test('still marks the streak and keeps later updates working', () async {
      var streakCompletions = 0;
      final cubit = await openCubit(
        onQuestRewarded: (_) async => throw StateError('database is locked'),
        onStreakCompleted: () async => streakCompletions++,
      );

      await cubit.completeQuest(_activeTimeQuest.id);
      await cubit.completeQuest(_feedQuest.id);
      await cubit.completeQuest(_quizQuest.id);

      expect(cubit.state.allCompleted, isTrue);
      expect(streakCompletions, 1);
    });
  });

  group('wired to the user balance', () {
    late AppDatabase db;
    late DailyQuestCubit cubit;

    Future<int> gems() async =>
        (await db.select(db.usersEntrie).getSingle()).gems;

    setUp(() async {
      db = await openDbWithUser('device', gems: 100);
      addTearDown(db.close);
      // Same wiring as app.dart.
      final xpCubit = XpCubit(UserRepository(db));
      addTearDown(xpCubit.close);
      cubit = await openCubit(onQuestRewarded: xpCubit.addGems);
    });

    test('a completed quest adds its gems to the balance', () async {
      await cubit.completeQuest(_quizQuest.id);

      expect(await gems(), 115);
    });

    test('finishing every quest adds all rewards', () async {
      await Future.wait([
        cubit.completeQuest(_activeTimeQuest.id),
        cubit.completeQuest(_feedQuest.id),
        cubit.completeQuest(_quizQuest.id),
      ]);

      expect(await gems(), 130);
    });
  });
}
