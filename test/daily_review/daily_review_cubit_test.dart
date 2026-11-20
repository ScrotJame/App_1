import 'dart:math';
import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/daily_quest/daily_quest_cubit.dart';
import 'package:test_abc/page/daily_quest/models/daily_quest_model.dart';
import 'package:test_abc/page/daily_review/daily_review_cubit.dart';
import 'package:test_abc/page/daily_review/data/daily_review_local_data_source.dart';
import 'package:test_abc/page/daily_review/data/daily_review_repository.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../repository/backup_test_support.dart';

class _MockDailyQuestCubit extends Mock implements DailyQuestCubit {}

class _FlakyHistory extends LearningHistoryRepository {
  _FlakyHistory(super.db);
  bool fail = true;
  int calls = 0;

  @override
  Future<void> recordAnswer({
    required String userKey,
    required int wordId,
    required int wordLevelSnapshot,
    required String sessionType,
    required bool isCorrect,
    DateTime? now,
  }) async {
    calls++;
    if (fail) throw Exception('disk');
    return super.recordAnswer(
        userKey: userKey,
        wordId: wordId,
        wordLevelSnapshot: wordLevelSnapshot,
        sessionType: sessionType,
        isCorrect: isCorrect,
        now: now);
  }
}

class _FlakyVocabulary extends VocabularyRepository {
  _FlakyVocabulary(super.db);
  bool failGetAllWords = false;

  @override
  Future<List<VocabularyEntry>> getAllWords() async {
    if (failGetAllWords) throw Exception('disk');
    return super.getAllWords();
  }
}

class _FakeDataSource implements DailyReviewLocalDataSource {
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
  const userKey = 'device';
  const alarmChannel = MethodChannel('com.example.test_abc/alarm');

  late AppDatabase db;
  late VocabularyRepository vocabulary;
  late LearningHistoryRepository history;
  late DailyReviewRepository reviews;
  late XpCubit xpCubit;
  late _MockDailyQuestCubit quest;

  DailyReviewCubit newCubit() {
    final cubit = DailyReviewCubit(reviews, vocabulary, history, xpCubit, quest,
        random: Random(3));
    addTearDown(cubit.close);
    return cubit;
  }

  Future<VocabularyEntry> word(int id) =>
      (db.select(db.vocabularyEntries)..where((t) => t.id.equals(id)))
          .getSingle();

  Future<UsersEntrieData> user() => db.select(db.usersEntrie).getSingle();

  /// Answers every remaining question; the first [correct] ones right.
  Future<({List<int> right, List<int> wrong})> answerAll(
    DailyReviewCubit cubit, {
    required int correct,
  }) async {
    final right = <int>[];
    final wrong = <int>[];
    var i = 0;
    while (cubit.state.phase == DailyReviewPhase.testing) {
      final q = cubit.state.currentQuestion;
      if (q == null) break;
      final isRight = i < correct;
      (isRight ? right : wrong).add(q.word.id);
      await cubit.selectAnswer(
          isRight ? q.correctIndex : (q.correctIndex + 1) % q.choices.length);
      await cubit.next();
      i++;
    }
    return (right: right, wrong: wrong);
  }

  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  setUp(() async {
    db = await openDbWithUser(userKey);
    addTearDown(db.close);
    vocabulary = VocabularyRepository(db);
    history = LearningHistoryRepository(db);
    reviews = DailyReviewRepository(_FakeDataSource(), vocabulary, history,
        random: Random(5));
    addTearDown(reviews.close);
    xpCubit = XpCubit(UserRepository(db));
    addTearDown(xpCubit.close);
    quest = _MockDailyQuestCubit();
    when(() => quest.onProgressByType(QuestType.completeQuiz))
        .thenAnswer((_) async {});

    UserSession.instance.syncFromUser(await user());
    addTearDown(UserSession.instance.clear);

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(alarmChannel, (_) async => true);
    addTearDown(() => messenger.setMockMethodCallHandler(alarmChannel, null));

    // Four learned words at level 2, due for a long time.
    for (final (w, m) in [('猫', 'cat'), ('犬', 'dog'), ('鳥', 'bird'), ('魚', 'fish')]) {
      final id = await vocabulary.insertWord(word: w, meaning: m);
      await (db.update(db.vocabularyEntries)..where((t) => t.id.equals(id)))
          .write(VocabularyEntriesCompanion(
        level: const Value(2),
        lastReviewed:
            Value(DateTime.now().subtract(const Duration(days: 30))),
      ));
    }
  });

  test('no learned word shows the empty screen', () async {
    await db.update(db.vocabularyEntries).write(
        const VocabularyEntriesCompanion(lastReviewed: Value(null)));
    final cubit = newCubit();

    await cubit.load();

    expect(cubit.state.phase, DailyReviewPhase.empty);
    expect(cubit.state.session, isNull);
  });

  test('a right answer raises the level, a wrong one lowers it, both logged',
      () async {
    final cubit = newCubit();
    await cubit.load();
    expect(cubit.state.phase, DailyReviewPhase.intro);
    expect(cubit.state.session?.total, 4);

    await cubit.start();
    final answered = await answerAll(cubit, correct: 2);

    expect(cubit.state.phase, DailyReviewPhase.result);
    for (final id in answered.right) {
      expect((await word(id)).level, 3);
      expect((await word(id)).correctCount, 1);
    }
    for (final id in answered.wrong) {
      expect((await word(id)).level, 1);
      expect((await word(id)).wrongCount, 1);
    }
    final logs = await db.select(db.learningHistoryLogs).get();
    expect(logs, hasLength(4));
    expect(logs.map((l) => l.sessionType).toSet(), {SessionType.dailyReview});
    expect(logs.map((l) => l.wordLevelSnapshot).toSet(), {2});
    expect(cubit.state.leveledUp.map((c) => c.wordId),
        unorderedEquals(answered.right));
    expect(cubit.state.leveledDown.map((c) => c.wordId),
        unorderedEquals(answered.wrong));
  });

  test('the reward is paid once, with the quest progress', () async {
    final cubit = newCubit();
    await cubit.load();
    await cubit.start();
    await answerAll(cubit, correct: 2);

    // 2 × level 3 (15 XP, 35 gems) + completion (30, 20). 2/4 < 0.8.
    expect((await user()).experience, 60);
    expect((await user()).gems, 90);
    expect(cubit.state.reward.totalXp, 60);
    verify(() => quest.onProgressByType(QuestType.completeQuiz)).called(1);

    final reopened = newCubit();
    await reopened.load();

    expect(reopened.state.session?.isCompleted, isTrue);
    expect((await user()).experience, 60);
    expect((await user()).gems, 90);
    verifyNever(() => quest.onProgressByType(QuestType.completeQuiz));
  });

  test('80% correct or more pays the accuracy bonus', () async {
    final cubit = newCubit();
    await cubit.load();
    await cubit.start();
    await answerAll(cubit, correct: 4);

    // 4 × 15 + 30 + 20 XP, 4 × 35 + 20 + 10 gems.
    expect((await user()).experience, 110);
    expect((await user()).gems, 170);
  });

  test('practice writes nothing and pays nothing', () async {
    final cubit = newCubit();
    await cubit.load();
    await cubit.start();
    await answerAll(cubit, correct: 4);
    clearInteractions(quest);
    final levels = {
      for (final id in cubit.state.session?.wordIds ?? <int>[])
        id: (await word(id)).level,
    };
    final logCount = (await db.select(db.learningHistoryLogs).get()).length;
    final xp = (await user()).experience;

    await cubit.practice();
    expect(cubit.state.mode, DailyReviewMode.practice);
    await answerAll(cubit, correct: 0);

    expect(cubit.state.phase, DailyReviewPhase.result);
    expect(cubit.state.resultCorrect, 0);
    expect(cubit.state.resultTotal, 4);
    for (final entry in levels.entries) {
      expect((await word(entry.key)).level, entry.value);
    }
    expect((await db.select(db.learningHistoryLogs).get()).length, logCount);
    expect((await user()).experience, xp);
    verifyNever(() => quest.onProgressByType(QuestType.completeQuiz));
  });

  test('leaving mid-way resumes at the first open question', () async {
    final cubit = newCubit();
    await cubit.load();
    await cubit.start();
    final q = cubit.state.currentQuestion;
    await cubit.selectAnswer(q?.correctIndex ?? 0);
    await cubit.close();

    final resumed = newCubit();
    await resumed.load();
    expect(resumed.state.session?.answeredCount, 1);

    await resumed.start();
    expect(resumed.state.currentIndex, 1);
    expect(resumed.state.questions, hasLength(4));
  });

  test('changing the preset keeps today\'s review as it is', () async {
    final cubit = newCubit();
    await cubit.load();

    await cubit.changePreset(10);

    expect(cubit.state.preset, 10);
    expect(await reviews.readPreset(userKey), 10);
    expect(cubit.state.session?.target, 20);
  });

  test('a retry after a failed save does not grade the word twice', () async {
    final flaky = _FlakyHistory(db);
    reviews = DailyReviewRepository(_FakeDataSource(), vocabulary, flaky,
        random: Random(5));
    addTearDown(reviews.close);
    final cubit = DailyReviewCubit(reviews, vocabulary, flaky, xpCubit, quest,
        random: Random(3));
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.start();
    final q = cubit.state.currentQuestion!;

    await cubit.selectAnswer(q.correctIndex);
    expect(cubit.state.hasAnsweredCurrent, isFalse);
    expect((await word(q.word.id)).level, 3);

    flaky.fail = false;
    await cubit.selectAnswer(q.correctIndex);

    expect((await word(q.word.id)).level, 3);
    expect((await word(q.word.id)).correctCount, 1);
    expect(cubit.state.session?.answeredCount, 1);
    expect(flaky.calls, 2);
    expect(await db.select(db.learningHistoryLogs).get(), hasLength(1));
  });

  test('a word already answered is skipped, never graded again', () async {
    final first = newCubit();
    await first.load();
    final session = first.state.session!;
    final loggedId = session.wordIds[1];
    // The app died after the database write of this word, before
    // SharedPreferences: the next open copies the answer.
    await history.recordAnswer(
      userKey: userKey,
      wordId: loggedId,
      wordLevelSnapshot: 2,
      sessionType: SessionType.dailyReview,
      isCorrect: true,
    );
    await first.close();

    final cubit = newCubit();
    await cubit.load();
    expect(cubit.state.session?.answers, {loggedId: true});
    await cubit.start();
    expect(cubit.state.currentIndex, 0);
    await answerAll(cubit, correct: 4);

    expect(cubit.state.phase, DailyReviewPhase.result);
    expect(cubit.state.session?.answeredCount, 4);
    expect((await word(loggedId)).level, 2);
    final logs = await (db.select(db.learningHistoryLogs)
          ..where((t) => t.wordId.equals(loggedId)))
        .get();
    expect(logs, hasLength(1));
  });

  test('retrying Finish after a failure past the claim pays once', () async {
    final flaky = _FlakyVocabulary(db);
    final source = _FakeDataSource();
    reviews = DailyReviewRepository(source, flaky, history, random: Random(5));
    addTearDown(reviews.close);
    final cubit = DailyReviewCubit(reviews, flaky, history, xpCubit, quest,
        random: Random(3));
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.start();
    for (var i = 0; i < 4; i++) {
      final q = cubit.state.currentQuestion!;
      await cubit.selectAnswer(q.correctIndex);
      if (i < 3) await cubit.next();
    }

    // complete() and the claim are saved, then reading the words fails.
    flaky.failGetAllWords = true;
    await cubit.next();
    expect(cubit.state.phase, DailyReviewPhase.testing);
    final xp = (await user()).experience;
    final gems = (await user()).gems;
    // 4 × 15 + 30 + 20 XP, 4 × 35 + 20 + 10 gems.
    expect(xp, 110);
    expect(gems, 170);

    flaky.failGetAllWords = false;
    await cubit.next();

    expect(cubit.state.phase, DailyReviewPhase.result);
    expect((await user()).experience, xp);
    expect((await user()).gems, gems);
    expect(await reviews.readRecentAccuracies(userKey), [1.0]);
    verify(() => quest.onProgressByType(QuestType.completeQuiz)).called(1);
    final stored = cubit.state.session;
    expect(stored?.isCompleted, isTrue);
    expect(stored?.rewardClaimed, isTrue);
  });

  test('a retry after a failed save shows the first choice', () async {
    final flaky = _FlakyHistory(db);
    reviews = DailyReviewRepository(_FakeDataSource(), vocabulary, flaky,
        random: Random(5));
    addTearDown(reviews.close);
    final cubit = DailyReviewCubit(reviews, vocabulary, flaky, xpCubit, quest,
        random: Random(3));
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.start();
    final q = cubit.state.currentQuestion!;
    final wrong = (q.correctIndex + 1) % q.choices.length;

    await cubit.selectAnswer(q.correctIndex);
    flaky.fail = false;
    await cubit.selectAnswer(wrong);

    expect(cubit.state.selectedAnswerIndex, q.correctIndex);
    expect(cubit.state.session?.answers, {q.word.id: true});
  });

  test('a finished review whose words were deleted stays done', () async {
    final cubit = newCubit();
    await cubit.load();
    await cubit.start();
    await answerAll(cubit, correct: 4);
    final xp = (await user()).experience;
    for (final id in cubit.state.session?.wordIds ?? <int>[]) {
      await vocabulary.deleteWord(id);
    }
    clearInteractions(quest);

    final reopened = newCubit();
    await reopened.load();
    expect(reopened.state.phase, DailyReviewPhase.intro);
    expect(reopened.state.session?.isCompleted, isTrue);
    expect(reopened.state.session?.total, 0);

    await reopened.practice();

    expect(reopened.state.phase, DailyReviewPhase.intro);
    expect((await user()).experience, xp);
    verifyNever(() => quest.onProgressByType(QuestType.completeQuiz));
  });
}
