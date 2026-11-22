import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/test_word/data/test_config_store.dart';
import 'package:test_abc/page/test_word/test_cubit.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../../repository/backup_test_support.dart';
import 'test_word_support.dart';

void main() {
  const userKey = 'device';
  const alarmChannel = MethodChannel('com.example.test_abc/alarm');

  late AppDatabase db;
  late VocabularyRepository vocabulary;
  late LearningHistoryRepository history;

  /// Waits for the config data first, so a setting made by the test is not
  /// sanitized away by the late load (e.g. a language with no word).
  Future<TestCubit> cubitWith({
    Set<String> voices = const {'ja'},
    Duration? autoAdvanceDelay,
  }) async {
    final cubit = newTestCubit(vocabulary, history,
        voices: voices, autoAdvanceDelay: autoAdvanceDelay);
    addTearDown(cubit.close);
    await cubit.ready;
    cubit.toggleTimer(false);
    return cubit;
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

    for (final (word, meaning, reading) in [
      ('猫', 'cat', 'ねこ'),
      ('犬', 'dog', 'いぬ'),
      ('鳥', 'bird', 'とり'),
      ('魚', 'fish', 'さかな'),
    ]) {
      await vocabulary.insertWord(
          word: word, meaning: meaning, pronunciation: reading, language: 'ja');
    }
  });

  group('setup', () {
    test('the saved setup is loaded when the page opens', () async {
      await TestConfigStore()
          .save(const TestConfig(kinds: {TestKind.typing}, enableTimer: false));

      final cubit = newTestCubit(vocabulary, history);
      addTearDown(cubit.close);
      await cubit.ready;

      expect(cubit.state.config.kinds, {TestKind.typing});
      expect(cubit.state.matchingWordCount, 4);
    });

    test('a choice made before the saved setup loads is kept', () async {
      await TestConfigStore()
          .save(const TestConfig(kinds: {TestKind.listening}));

      final cubit = newTestCubit(vocabulary, history);
      addTearDown(cubit.close);
      cubit.toggleKind(TestKind.typing);
      await cubit.ready;

      expect(cubit.state.config.kinds, {TestKind.choice, TestKind.typing});
    });

    test('the last kind cannot be removed', () async {
      final cubit = await cubitWith();
      final messages = <String>[];
      final sub = cubit.messageController.stream.listen(messages.add);
      addTearDown(sub.cancel);

      cubit.toggleKind(TestKind.choice);
      await pumpEventQueue();

      expect(cubit.state.config.kinds, {TestKind.choice});
      expect(messages, [S.current.test_kind_keep_one]);
    });

    test('changing the timer mode picks a time of that mode', () async {
      final cubit = await cubitWith();

      cubit.setTimerMode(TimerMode.perWord);
      expect(cubit.state.config.timeLimitSeconds,
          TestConfig.defaultPerQuestionSeconds);

      cubit.setTimerMode(TimerMode.total);
      expect(cubit.state.config.timeLimitSeconds,
          TestConfig.defaultTotalSeconds);
    });

    test('starting saves the setup', () async {
      final cubit = await cubitWith();
      cubit.toggleKind(TestKind.trueFalse);

      await cubit.startTest();

      expect(await TestConfigStore().load(), cubit.state.config);
    });
  });

  group('kinds', () {
    test('a test mixes the selected kinds', () async {
      final cubit = await cubitWith();
      for (final kind in TestKind.values) {
        if (kind != TestKind.choice) cubit.toggleKind(kind);
      }

      await cubit.startTest();

      expect(cubit.state.phase, TestPhase.testing);
      expect(cubit.state.questions.map((q) => q.kind).toSet(),
          TestKind.values.toSet());
    });

    test('without a voice, listening is dropped with a warning', () async {
      final cubit = await cubitWith(voices: {});
      final messages = <String>[];
      final sub = cubit.messageController.stream.listen(messages.add);
      addTearDown(sub.cancel);
      cubit.toggleKind(TestKind.listening);

      await cubit.startTest();
      await pumpEventQueue();

      expect(cubit.state.questions.any((q) => q is ListeningQuestion), isFalse);
      expect(messages, [S.current.test_warning_no_voice('ja')]);
    });

    test('no question at all keeps the config screen with an error', () async {
      final cubit = await cubitWith();
      cubit.setLanguageFilter('ko');

      await cubit.startTest();

      expect(cubit.state.phase, TestPhase.config);
      expect(cubit.state.loadStatus, LOADSTATUS.FAILED);
      expect(cubit.state.errorMessage, S.current.test_not_enough_words);
    });

    test('each kind is graded by its own rule', () async {
      final cubit = await cubitWith();
      for (final kind in TestKind.values) {
        if (kind != TestKind.choice) cubit.toggleKind(kind);
      }
      await cubit.startTest();

      for (var i = 0; i < cubit.state.questions.length; i++) {
        cubit.submitAnswer(correctAnswerFor(cubit.state.questions[i]));
        expect(cubit.state.isCurrentCorrect, isTrue, reason: 'question $i');
        if (!cubit.state.isLastQuestion) cubit.nextQuestion();
      }
      expect(cubit.state.correctCount, 4);
      expect(cubit.state.kindStats.values,
          everyElement((correct: 1, total: 1)));
    });

    test('two quick taps on Start build one test', () async {
      final cubit = newTestCubit(vocabulary, history);
      addTearDown(cubit.close);
      cubit.toggleTimer(false);
      var testingEmissions = 0;
      final sub = cubit.stream
          .where((s) => s.phase == TestPhase.testing)
          .listen((_) => testingEmissions++);
      addTearDown(sub.cancel);

      await Future.wait([cubit.startTest(), cubit.startTest()]);
      await pumpEventQueue();

      expect(testingEmissions, 1);
      expect(cubit.state.phase, TestPhase.testing);
    });

    test('retry builds a new test after one was started', () async {
      final cubit = await cubitWith();
      await cubit.startTest();
      cubit.goToConfig();

      await cubit.retryTest();

      expect(cubit.state.phase, TestPhase.testing);
    });

    test('a second answer to the same question is ignored', () async {
      final cubit = await cubitWith();
      await cubit.startTest();
      final question = cubit.state.questions.first;

      cubit.submitAnswer(wrongAnswerFor(question));
      cubit.submitAnswer(correctAnswerFor(question));

      expect(cubit.state.isCurrentCorrect, isFalse);
      expect(cubit.state.score, 0);
    });
  });

  group('hints', () {
    Future<TestCubit> startWith(TestKind kind) async {
      final cubit = await cubitWith();
      cubit.toggleKind(kind);
      if (kind != TestKind.choice) cubit.toggleKind(TestKind.choice);
      await cubit.startTest();
      return cubit;
    }

    test('a typing hint shows one more character', () async {
      final cubit = await startWith(TestKind.typing);

      cubit.useHint();
      cubit.useHint();

      expect(cubit.state.currentRevealedChars, 2);
      expect(cubit.state.hintsUsed, 2);
    });

    test('a typing hint stops at the end of the answer', () async {
      final cubit = await startWith(TestKind.typing);
      final question = cubit.state.currentQuestion as TypingQuestion;

      for (var i = 0; i < 5; i++) {
        cubit.useHint();
      }

      expect(cubit.state.currentRevealedChars,
          question.hintLength < 3 ? question.hintLength : 3);
    });

    test('a choice hint removes a wrong choice', () async {
      final cubit = await startWith(TestKind.choice);
      final question = cubit.state.currentQuestion as MultipleChoiceQuestion;

      cubit.useHint();

      expect(cubit.state.currentEliminatedIndexes, hasLength(1));
      expect(cubit.state.currentEliminatedIndexes,
          isNot(contains(question.correctIndex)));
    });

    test('true / false has no hint', () async {
      final cubit = await startWith(TestKind.trueFalse);

      expect(cubit.state.canUseHint, isFalse);
      cubit.useHint();

      expect(cubit.state.hintsUsed, 0);
    });
  });

  group('moving on', () {
    test('a correct answer moves on by itself', () async {
      final cubit =
          await cubitWith(autoAdvanceDelay: const Duration(milliseconds: 10));
      await cubit.startTest();

      cubit.submitAnswer(correctAnswerFor(cubit.state.questions.first));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.currentIndex, 1);
    });

    test('a wrong answer waits for "next"', () async {
      final cubit =
          await cubitWith(autoAdvanceDelay: const Duration(milliseconds: 10));
      await cubit.startTest();

      cubit.submitAnswer(wrongAnswerFor(cubit.state.questions.first));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.currentIndex, 0);
    });

    test('typing gets twice the time per question', () async {
      final cubit = await cubitWith();
      cubit.toggleKind(TestKind.typing);
      cubit.toggleKind(TestKind.choice);
      cubit.setTimerMode(TimerMode.perWord);
      cubit.setTimeLimit(10);
      cubit.toggleTimer(true);

      await cubit.startTest();

      expect(cubit.state.remainingSeconds, 20);
    });
  });
}
