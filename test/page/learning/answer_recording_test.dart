import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/learning/flash_card/flash_card_cubit.dart';
import 'package:test_abc/page/learning/quiz_game/quiz_game_cubit.dart';
import 'package:test_abc/page/learning/word_matching/word_matching_cubit.dart';
import 'package:test_abc/page/test_word/test_cubit.dart';
import 'package:test_abc/page/training_feed/training_feed_cubit.dart';
import 'package:test_abc/page/training_feed/training_feed_engine.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/service/tts_service.dart';

import '../../repository/backup_test_support.dart';

/// Every learning mode has to leave a trace of each answer: the word's
/// correct/wrong counter and a row in the learning history.
void main() {
  const userKey = 'device';
  const alarmChannel = MethodChannel('com.example.test_abc/alarm');

  late AppDatabase db;
  late VocabularyRepository vocabulary;
  late LearningHistoryRepository history;
  late List<int> wordIds;

  Future<VocabularyEntry> word(int id) =>
      (db.select(db.vocabularyEntries)..where((t) => t.id.equals(id)))
          .getSingle();

  Future<List<LearningHistoryLog>> logs() =>
      db.select(db.learningHistoryLogs).get();

  Future<int> totalAnswers() async {
    final words = await db.select(db.vocabularyEntries).get();
    return words.fold<int>(0, (sum, w) => sum + w.correctCount + w.wrongCount);
  }

  /// Answers are recorded without blocking the UI, so wait for them to land.
  Future<void> waitForAnswers(int count) async {
    for (var i = 0; i < 200; i++) {
      if (await totalAnswers() >= count && (await logs()).length >= count) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('Expected $count recorded answers, found ${await totalAnswers()} '
        'counted and ${(await logs()).length} in the history.');
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

    wordIds = [
      await vocabulary.insertWord(word: '猫', meaning: 'cat'),
      await vocabulary.insertWord(word: '犬', meaning: 'dog'),
      await vocabulary.insertWord(word: '鳥', meaning: 'bird'),
      await vocabulary.insertWord(word: '魚', meaning: 'fish'),
    ];
  });

  group('Quiz game', () {
    late QuizGameCubit cubit;

    setUp(() async {
      cubit = QuizGameCubit(vocabulary, historyRepository: history);
      addTearDown(cubit.close);
      await cubit.start();
    });

    test('a correct answer is recorded for the asked word', () async {
      final question = cubit.state.currentQuestion;
      final wordId = question?.wordId ?? -1;

      cubit.selectAnswer('correct_$wordId');
      await waitForAnswers(1);

      final asked = await word(wordId);
      expect(asked.word, question?.word);
      expect(asked.correctCount, 1);
      expect(asked.wrongCount, 0);
      final log = (await logs()).single;
      expect(log.wordId, wordId);
      expect(log.sessionType, 'Quiz');
      expect(log.isCorrect, isTrue);
      expect(log.userKey, userKey);
    });

    test('a wrong answer is recorded for the asked word', () async {
      final question = cubit.state.currentQuestion;
      final wordId = question?.wordId ?? -1;
      final wrongOption = question?.options.firstWhere((o) => !o.isCorrect);

      cubit.selectAnswer(wrongOption?.id ?? '');
      await waitForAnswers(1);

      final asked = await word(wordId);
      expect(asked.correctCount, 0);
      expect(asked.wrongCount, 1);
      expect((await logs()).single.isCorrect, isFalse);
    });

    test('tapping again on an answered question records nothing more',
        () async {
      final wordId = cubit.state.currentQuestion?.wordId ?? -1;

      cubit.selectAnswer('correct_$wordId');
      cubit.selectAnswer('correct_$wordId');
      await waitForAnswers(1);
      await pumpEventQueue();

      expect(await totalAnswers(), 1);
      expect(await logs(), hasLength(1));
    });
  });

  group('Word matching', () {
    late WordMatchingCubit cubit;

    setUp(() async {
      cubit = WordMatchingCubit(vocabulary, CompanionRepository(db), history);
      addTearDown(cubit.close);
      await cubit.start();
    });

    test('a matched pair is a correct answer for that word', () async {
      final id = wordIds[1];

      cubit.selectLeftItem(id);
      cubit.selectRightItem(id);
      await waitForAnswers(1);

      expect((await word(id)).correctCount, 1);
      final log = (await logs()).single;
      expect(log.wordId, id);
      expect(log.sessionType, 'Matching');
      expect(log.isCorrect, isTrue);
    });

    test('a wrong pair is a wrong answer for the word, not the meaning',
        () async {
      final wordId = wordIds[0];
      final pickedMeaningId = wordIds[2];

      cubit.selectLeftItem(wordId);
      cubit.selectRightItem(pickedMeaningId);
      await waitForAnswers(1);

      expect((await word(wordId)).wrongCount, 1);
      final meaningWord = await word(pickedMeaningId);
      expect(meaningWord.wrongCount, 0);
      expect(meaningWord.correctCount, 0);
      final log = (await logs()).single;
      expect(log.wordId, wordId);
      expect(log.isCorrect, isFalse);
    });
  });

  group('Flashcard', () {
    late FlashCardCubit cubit;

    setUp(() async {
      cubit = FlashCardCubit(vocabulary, CompanionRepository(db), history);
      addTearDown(cubit.close);
      await cubit.start();
    });

    test('"again" counts as not remembered', () async {
      final id = cubit.state.currentCard?.word.id ?? -1;

      await cubit.rateCard(DifficultyRating.again);

      final rated = await word(id);
      expect(rated.wrongCount, 1);
      expect(rated.correctCount, 0);
      final log = (await logs()).single;
      expect(log.wordId, id);
      expect(log.sessionType, 'Flashcard');
      expect(log.isCorrect, isFalse);
    });

    test('any other rating counts as remembered', () async {
      final firstId = cubit.state.currentCard?.word.id ?? -1;
      await cubit.rateCard(DifficultyRating.hard);
      final secondId = cubit.state.currentCard?.word.id ?? -1;
      await cubit.rateCard(DifficultyRating.easy);

      expect(secondId, isNot(firstId));
      expect((await word(firstId)).correctCount, 1);
      expect((await word(secondId)).correctCount, 1);
      expect((await logs()).every((l) => l.isCorrect), isTrue);
    });

    test('a rating leaves the level and the review wait alone', () async {
      final id = cubit.state.currentCard?.word.id ?? -1;

      await cubit.rateCard(DifficultyRating.good);

      final rated = await word(id);
      expect(rated.level, 0);
      expect(rated.lastReviewed, isNull);
      expect(rated.nextReview, isNull);
      expect(rated.repetitions, 0);
      expect(rated.interval, 0);
      expect(rated.easeFactor, 2.5);
    });
  });

  group('Training feed', () {
    late TrainingFeedCubit cubit;

    /// The first unanswered card of [type]; loads more cards until one shows.
    Future<TrainingFeedCard> nextCard(TrainingFeedCardType type) async {
      for (var round = 0; round < 30; round++) {
        final matches = cubit.state.cards
            .where((c) => c.type == type && !c.isAnswered && c.word != null);
        if (matches.isNotEmpty) return matches.first;
        await cubit.onPageChanged(cubit.state.cards.length - 1);
      }
      fail('The feed never produced a $type card.');
    }

    int wrongChoice(TrainingFeedCard card) =>
        ((card.correctChoiceIndex ?? 0) + 1) % card.choices.length;

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
        // Let the reward of a correct answer finish before the DB closes.
        await pumpEventQueue();
        await cubit.close();
      });
      await cubit.load();
    });

    test('a correct quiz answer is recorded', () async {
      final card = await nextCard(TrainingFeedCardType.quiz);
      final id = card.word?.word.id ?? -1;

      cubit.answerQuizCard(card.id, card.correctChoiceIndex ?? -1);
      await waitForAnswers(1);

      expect((await word(id)).correctCount, 1);
      final log = (await logs()).single;
      expect(log.wordId, id);
      expect(log.sessionType, 'Feed');
      expect(log.isCorrect, isTrue);
    });

    test('a wrong quiz answer is recorded', () async {
      final card = await nextCard(TrainingFeedCardType.quiz);
      final id = card.word?.word.id ?? -1;

      cubit.answerQuizCard(card.id, wrongChoice(card));
      await waitForAnswers(1);

      final answered = await word(id);
      expect(answered.wrongCount, 1);
      expect(answered.correctCount, 0);
      expect((await logs()).single.isCorrect, isFalse);
    });

    test('an audio quiz answer is recorded', () async {
      final card = await nextCard(TrainingFeedCardType.audioQuiz);
      final id = card.word?.word.id ?? -1;

      cubit.answerAudioQuizCard(card.id, card.correctChoiceIndex ?? -1);
      await waitForAnswers(1);

      expect((await word(id)).correctCount, 1);
      expect((await logs()).single.sessionType, 'Feed');
    });

    test('answering the same card twice records one answer', () async {
      final card = await nextCard(TrainingFeedCardType.quiz);

      cubit.answerQuizCard(card.id, wrongChoice(card));
      cubit.answerQuizCard(card.id, card.correctChoiceIndex ?? -1);
      await waitForAnswers(1);
      await pumpEventQueue();

      expect(await totalAnswers(), 1);
      expect(await logs(), hasLength(1));
    });

    test('revealing a learn card is not an answer', () async {
      final card = await nextCard(TrainingFeedCardType.learn);

      cubit.revealCard(card.id);
      await pumpEventQueue();

      expect(await totalAnswers(), 0);
      expect(await logs(), isEmpty);
    });
  });

  group('Test', () {
    late TestCubit cubit;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(alarmChannel, (_) async => null);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(alarmChannel, null));

      cubit = TestCubit(vocabulary, history);
      addTearDown(cubit.close);
      cubit.toggleTimer(false);
      await cubit.startTest();
    });

    /// Answers every question; the first [correctAnswers] ones correctly.
    Future<void> takeTest({required int correctAnswers}) async {
      final total = cubit.state.questions.length;
      for (var i = 0; i < total; i++) {
        final question = cubit.state.questions[i];
        final choice = i < correctAnswers
            ? question.correctIndex
            : (question.correctIndex + 1) % question.choices.length;
        cubit.selectAnswer(choice);
        cubit.nextQuestion();
      }
      for (var i = 0; i < 200; i++) {
        if (cubit.state.phase == TestPhase.result) return;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('The test never reached the result screen.');
    }

    test('every answer of a finished test is counted on its word', () async {
      final questions = cubit.state.questions;
      expect(questions, hasLength(4));

      await takeTest(correctAnswers: 3);

      for (var i = 0; i < questions.length; i++) {
        final answered = await word(questions[i].word.word.id);
        expect(answered.correctCount, i < 3 ? 1 : 0, reason: 'question $i');
        expect(answered.wrongCount, i < 3 ? 0 : 1, reason: 'question $i');
      }
    });

    test('the history keeps the level each word had before the test',
        () async {
      await takeTest(correctAnswers: 2);

      final rows = await logs();
      expect(rows, hasLength(4));
      expect(rows.every((l) => l.sessionType == 'Test'), isTrue);
      expect(rows.every((l) => l.wordLevelSnapshot == 0), isTrue);
      expect(rows.where((l) => l.isCorrect), hasLength(2));
    });

    test('correct answers still level the word up', () async {
      final questions = cubit.state.questions;

      await takeTest(correctAnswers: 1);

      expect((await word(questions[0].word.word.id)).level, 1);
      expect((await word(questions[1].word.word.id)).level, 0);
    });
  });
}
