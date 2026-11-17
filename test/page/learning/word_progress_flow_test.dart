import 'dart:math';
import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/list_word/list_word_cubit.dart';
import 'package:test_abc/page/test_word/test_cubit.dart';
import 'package:test_abc/page/training_feed/training_feed_cubit.dart';
import 'package:test_abc/page/training_feed/training_feed_engine.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/service/alarm_service.dart';
import 'package:test_abc/service/tts_service.dart';

import '../../repository/backup_test_support.dart';

/// The screens that move a word's progress, driven end to end: they all go
/// through the word's level, and there is one review reminder for the app.
void main() {
  const userKey = 'device';
  const alarmChannel = MethodChannel('com.example.test_abc/alarm');

  late AppDatabase db;
  late VocabularyRepository vocabulary;
  late LearningHistoryRepository history;
  late List<int> wordIds;
  late List<MethodCall> alarmCalls;

  Future<VocabularyEntry> word(int id) =>
      (db.select(db.vocabularyEntries)..where((t) => t.id.equals(id)))
          .getSingle();

  Future<List<int>> levels() async =>
      [for (final id in wordIds) (await word(id)).level];

  Future<int> totalLearned() async =>
      (await db.select(db.usersEntrie).getSingle()).totalLearned;

  /// Makes every word look like its last review was [ago] in the past.
  Future<void> rest(Duration ago) async {
    for (final id in wordIds) {
      final lastReviewed = (await word(id)).lastReviewed;
      if (lastReviewed == null) continue;
      await (db.update(db.vocabularyEntries)..where((t) => t.id.equals(id)))
          .write(VocabularyEntriesCompanion(
        lastReviewed: Value(lastReviewed.subtract(ago)),
      ));
    }
  }

  List<MethodCall> callsOf(String method) =>
      alarmCalls.where((c) => c.method == method).toList();

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

    alarmCalls = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(alarmChannel, (call) async {
      alarmCalls.add(call);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(alarmChannel, null));

    wordIds = [
      await vocabulary.insertWord(word: '猫', meaning: 'cat'),
      await vocabulary.insertWord(word: '犬', meaning: 'dog'),
      await vocabulary.insertWord(word: '鳥', meaning: 'bird'),
      await vocabulary.insertWord(word: '魚', meaning: 'fish'),
    ];
  });

  group('Test', () {
    late TestCubit cubit;

    setUp(() {
      cubit = TestCubit(vocabulary, history);
      addTearDown(cubit.close);
      cubit.toggleTimer(false);
    });

    /// Runs one whole test. [isCorrect] decides the answer for each word id.
    Future<void> takeTest({bool Function(int wordId)? isCorrect}) async {
      await cubit.startTest();
      final total = cubit.state.questions.length;
      expect(total, wordIds.length);
      for (var i = 0; i < total; i++) {
        final question = cubit.state.questions[i];
        final correct = isCorrect?.call(question.word.word.id) ?? true;
        cubit.selectAnswer(correct
            ? question.correctIndex
            : (question.correctIndex + 1) % question.choices.length);
        cubit.nextQuestion();
      }
      for (var i = 0; i < 200; i++) {
        if (cubit.state.phase == TestPhase.result) return;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('The test never reached the result screen.');
    }

    test('five tests in a row level each word up once, not to mastered',
        () async {
      for (var i = 0; i < 5; i++) {
        await takeTest();
      }

      expect(await levels(), [1, 1, 1, 1]);
      expect(await totalLearned(), 0);
    });

    test('a repeated test reports the answers that did not count', () async {
      await takeTest();
      expect(cubit.state.leveledUpWords, hasLength(4));
      expect(cubit.state.notDueCount, 0);

      await takeTest();

      expect(cubit.state.leveledUpWords, isEmpty);
      expect(cubit.state.notDueCount, 4);
      expect(cubit.state.correctCount, 4);
    });

    test('the same test counts again after the words have rested', () async {
      await takeTest();
      await rest(const Duration(minutes: 15));

      await takeTest();

      expect(await levels(), [2, 2, 2, 2]);
      expect(cubit.state.leveledUpWords.map((w) => w.level), everyElement(2));
      expect(cubit.state.notDueCount, 0);
    });

    test('a wrong answer cannot be fixed by retaking the test at once',
        () async {
      final missed = wordIds[2];

      await takeTest(isCorrect: (id) => id != missed);
      await takeTest();

      expect((await word(missed)).level, 0);
      expect(cubit.state.notDueCount, 4);
    });

    test('mastering a word in a test counts it once', () async {
      final target = wordIds[0];
      await (db.update(db.vocabularyEntries)
            ..where((t) => t.id.equals(target)))
          .write(VocabularyEntriesCompanion(
        level: const Value(4),
        lastReviewed: Value(DateTime.now().subtract(const Duration(hours: 3))),
      ));

      await takeTest();
      await takeTest();

      expect((await word(target)).level, WordStatus.masteredLevel);
      expect(await totalLearned(), 1);
      expect(await vocabulary.isWordAlreadyMastered(target, userKey), isTrue);
    });

    test('one test sets one reminder, not one alarm per word', () async {
      final before = DateTime.now();

      await takeTest(isCorrect: (id) => id != wordIds[3]);

      expect(callsOf('scheduleAlarm'), isEmpty);
      final reminders = callsOf('scheduleReviewAlarm');
      expect(reminders, hasLength(1));
      final args = reminders.single.arguments as Map;
      expect(args['message'], S.current.review_reminder_message);
      // The missed word is at level 0 and is due first, 5 minutes on.
      final at =
          DateTime.fromMillisecondsSinceEpoch(args['triggerAtMillis'] as int);
      expect(at.isAfter(before), isTrue);
      expect(await vocabulary.nextReviewReminderTime(now: before), at);
    });
  });

  group('Training feed buttons', () {
    late TrainingFeedCubit cubit;
    late int cardWordId;

    setUp(() async {
      final xpCubit = XpCubit(UserRepository(db));
      addTearDown(xpCubit.close);
      cubit = TrainingFeedCubit(
        vocabulary,
        xpCubit,
        CompanionRepository(db),
        TtsService(),
        engine: TrainingFeedEngine(random: Random(7)),
        historyRepository: history,
      );
      addTearDown(() async {
        await pumpEventQueue();
        await cubit.close();
      });
      await cubit.load();

      final index = cubit.state.cards.indexWhere((c) => c.word != null);
      expect(index, isNot(-1));
      await cubit.onPageChanged(index);
      cardWordId = cubit.state.currentCard?.word?.word.id ?? -1;
    });

    test('"đã thuộc" masters the word and counts it', () async {
      await cubit.markCurrentCardAsLearned();

      expect((await word(cardWordId)).level, WordStatus.masteredLevel);
      expect(await totalLearned(), 1);
    });

    test('"đã thuộc" twice counts the word once', () async {
      await cubit.markCurrentCardAsLearned();
      await cubit.markCurrentCardAsLearned();

      expect(await totalLearned(), 1);
    });

    test('"ôn lại" then mastering again does not count the word twice',
        () async {
      await cubit.markCurrentCardAsLearned();

      await cubit.saveCurrentCardForReview();
      expect((await word(cardWordId)).level, WordStatus.masteredLevel - 1);
      expect(await totalLearned(), 0);

      await cubit.markCurrentCardAsLearned();
      expect(await totalLearned(), 1);
    });

    test('"ôn lại" on a new word leaves it as it is', () async {
      await cubit.saveCurrentCardForReview();

      expect((await word(cardWordId)).level, 0);
      expect(await totalLearned(), 0);
    });
  });

  group('Review reminder', () {
    test('deleting the only reviewed word cancels the reminder', () async {
      await vocabulary.restartReviewWait(wordIds[0], userKey);
      await AlarmService.syncReviewReminder(vocabulary);
      expect(callsOf('scheduleReviewAlarm'), hasLength(1));

      final listCubit = ListWordCubit(vocabulary, TtsService());
      addTearDown(listCubit.close);
      await listCubit.deleteWord(wordIds[0]);
      await pumpEventQueue();

      expect(callsOf('cancelReviewAlarm'), hasLength(1));
      expect(callsOf('scheduleReviewAlarm'), hasLength(1));
    });

    test('deleting one of two reviewed words keeps a reminder for the other',
        () async {
      await vocabulary.restartReviewWait(wordIds[0], userKey);
      await vocabulary.levelUpIfDue(wordIds[1], userKey);

      final listCubit = ListWordCubit(vocabulary, TtsService());
      addTearDown(listCubit.close);
      await listCubit.deleteWord(wordIds[0]);
      await pumpEventQueue();

      expect(callsOf('cancelReviewAlarm'), isEmpty);
      final args = callsOf('scheduleReviewAlarm').single.arguments as Map;
      expect(
        DateTime.fromMillisecondsSinceEpoch(args['triggerAtMillis'] as int),
        await vocabulary.nextReviewReminderTime(
          now: DateTime.now().subtract(const Duration(seconds: 5)),
        ),
      );
    });

    test('nothing is sent to the alarm channel on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await vocabulary.restartReviewWait(wordIds[0], userKey);

        await AlarmService.syncReviewReminder(vocabulary);
        await AlarmService.schedule('message', 10);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(alarmCalls, isEmpty);
    });

    test('a missing native handler does not throw', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(alarmChannel, null);
      await vocabulary.restartReviewWait(wordIds[0], userKey);

      await expectLater(AlarmService.syncReviewReminder(vocabulary), completes);
    });
  });
}
