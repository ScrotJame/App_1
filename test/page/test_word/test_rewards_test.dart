import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/test_word/test_cubit.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../../repository/backup_test_support.dart';
import 'test_word_support.dart';

/// What a finished test pays, and that it can only be finished once.
void main() {
  const userKey = 'device';
  const alarmChannel = MethodChannel('com.example.test_abc/alarm');

  late AppDatabase db;
  late VocabularyRepository vocabulary;
  late LearningHistoryRepository history;
  late TestCubit cubit;
  late List<int> wordIds;

  Future<void> waitForResult() async {
    for (var i = 0; i < 200; i++) {
      if (cubit.state.phase == TestPhase.result) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('The test never reached the result screen.');
  }

  /// Answers every question; [correctAnswers] of them correctly.
  Future<void> takeTest({required int correctAnswers}) async {
    await cubit.startTest();
    final total = cubit.state.questions.length;
    for (var i = 0; i < total; i++) {
      final question = cubit.state.questions[i];
      cubit.submitAnswer(i < correctAnswers
          ? correctAnswerFor(question)
          : wrongAnswerFor(question));
      cubit.nextQuestion();
    }
    await waitForResult();
  }

  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  setUp(() async {
    db = await openDbWithUser(userKey);
    addTearDown(db.close);
    vocabulary = VocabularyRepository(db);
    history = LearningHistoryRepository(db);

    final user = await db.select(db.usersEntrie).getSingle();
    UserSession.instance.syncFromUser(user);
    addTearDown(UserSession.instance.clear);

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(alarmChannel, (_) async => true);
    addTearDown(() => messenger.setMockMethodCallHandler(alarmChannel, null));

    wordIds = [
      await vocabulary.insertWord(word: '猫', meaning: 'cat'),
      await vocabulary.insertWord(word: '犬', meaning: 'dog'),
      await vocabulary.insertWord(word: '鳥', meaning: 'bird'),
      await vocabulary.insertWord(word: '魚', meaning: 'fish'),
    ];

    cubit = newTestCubit(vocabulary, history);
    addTearDown(cubit.close);
    cubit.toggleTimer(false);
  });

  group('rewards', () {
    test('XP has its own scale, separate from gems', () {
      for (var level = 1; level <= 6; level++) {
        expect(TestState.xpForLevel(level), greaterThan(0));
        expect(TestState.gemsForLevel(level), greaterThan(0));
      }
      expect(
        [for (var level = 1; level <= 6; level++) TestState.xpForLevel(level)],
        [5, 10, 15, 25, 40, 40],
      );
      expect(
        [
          for (var level = 1; level <= 6; level++)
            TestState.gemsForLevel(level)
        ],
        [10, 20, 35, 50, 75, 75],
      );
    });

    test('each word that levelled up pays XP and gems for its new level',
        () async {
      await takeTest(correctAnswers: 3);

      expect(cubit.state.leveledUpWords, hasLength(3));
      expect(cubit.state.xpEarned, 3 * TestState.xpForLevel(1));
      expect(cubit.state.gemsEarned, 3 * TestState.gemsForLevel(1));
    });

    test('the reward grows with the level the word reaches', () async {
      // The first word is at level 2 and rested long enough to be due.
      await (db.update(db.vocabularyEntries)
            ..where((t) => t.id.equals(wordIds.first)))
          .write(VocabularyEntriesCompanion(
        level: const Value(2),
        lastReviewed:
            Value(DateTime.now().subtract(const Duration(days: 30))),
      ));

      await takeTest(correctAnswers: 4);

      // 15 + 3 * 5 XP. Half of the gems (the old formula) would be 32.
      expect(cubit.state.xpEarned, 30);
      expect(
        cubit.state.xpEarned,
        TestState.xpForLevel(3) + 3 * TestState.xpForLevel(1),
      );
      expect(
        cubit.state.gemsEarned,
        TestState.gemsForLevel(3) + 3 * TestState.gemsForLevel(1),
      );
    });

    test('a test with only wrong answers pays nothing', () async {
      await takeTest(correctAnswers: 0);

      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
    });

    test('repeating the test right away pays nothing', () async {
      await takeTest(correctAnswers: 4);
      expect(cubit.state.xpEarned, greaterThan(0));

      await takeTest(correctAnswers: 4);

      expect(cubit.state.leveledUpWords, isEmpty);
      expect(cubit.state.notDueCount, 0);
      expect(cubit.state.cappedCount, 4);
      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
    });

    test('a new test starts without the rewards of the previous one',
        () async {
      await takeTest(correctAnswers: 4);

      await cubit.startTest();

      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
    });
  });

  group('finishing', () {
    test('ending the test twice writes levels and history once', () async {
      await cubit.startTest();
      final total = cubit.state.questions.length;
      for (var i = 0; i < total - 1; i++) {
        cubit.submitAnswer(correctAnswerFor(cubit.state.questions[i]));
        cubit.nextQuestion();
      }
      cubit.submitAnswer(correctAnswerFor(cubit.state.questions[total - 1]));

      // The timer running out and the tap on "next" arriving together.
      cubit.nextQuestion();
      cubit.nextQuestion();
      await waitForResult();
      await pumpEventQueue();

      expect(await db.select(db.learningHistoryLogs).get(), hasLength(4));
      final words = await db.select(db.vocabularyEntries).get();
      expect(words.every((w) => w.level == 1), isTrue);
      expect(words.every((w) => w.correctCount == 1), isTrue);
      expect(cubit.state.leveledUpWords, hasLength(4));
      expect(cubit.state.notDueCount, 0);
    });

    test('answers are ignored once the test is being finished', () async {
      await cubit.startTest();
      final total = cubit.state.questions.length;
      for (var i = 0; i < total; i++) {
        cubit.submitAnswer(correctAnswerFor(cubit.state.questions[i]));
        cubit.nextQuestion();
      }
      final scoreAtEnd = cubit.state.score;

      cubit.submitAnswer(const ChoiceAnswer(0));
      await waitForResult();

      expect(cubit.state.score, scoreAtEnd);
    });

    test('without a user the result is still shown, with no reward',
        () async {
      await cubit.startTest();
      UserSession.instance.clear();
      final total = cubit.state.questions.length;
      for (var i = 0; i < total; i++) {
        cubit.submitAnswer(correctAnswerFor(cubit.state.questions[i]));
        cubit.nextQuestion();
      }
      await waitForResult();

      expect(cubit.state.isLevelingUp, isFalse);
      expect(cubit.state.correctCount, 4);
      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
      final words = await db.select(db.vocabularyEntries).get();
      expect(words.every((w) => w.level == 0), isTrue);
    });
  });
}
