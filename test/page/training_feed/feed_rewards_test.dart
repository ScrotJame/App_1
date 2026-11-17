import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/models/tag_vocab.dart';
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

/// The feed pays for answers that could have been wrong, never for swiping,
/// revealing or tapping a button.
void main() {
  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  group('cubit', () {
    const userKey = 'device';

    late AppDatabase db;
    late TrainingFeedCubit cubit;
    late List<String> messages;

    Future<UsersEntrieData> readUser() =>
        db.select(db.usersEntrie).getSingle();

    /// The first untouched card of [type]; loads more cards until one shows.
    Future<TrainingFeedCard> nextCard(TrainingFeedCardType type) async {
      for (var round = 0; round < 40; round++) {
        final matches = cubit.state.cards.where((c) =>
            c.type == type && !c.isAnswered && !c.isCompleted && !c.isRevealed);
        if (matches.isNotEmpty) return matches.first;
        await cubit.onPageChanged(cubit.state.cards.length - 1);
      }
      fail('The feed never produced a $type card.');
    }

    Future<void> answerQuiz({required bool correctly}) async {
      final card = await nextCard(TrainingFeedCardType.quiz);
      final correct = card.correctChoiceIndex ?? 0;
      cubit.answerQuizCard(
        card.id,
        correctly ? correct : (correct + 1) % card.choices.length,
      );
      await pumpEventQueue();
    }

    setUp(() async {
      db = await openDbWithUser(userKey);
      addTearDown(db.close);
      final vocabulary = VocabularyRepository(db);

      final user = await db.select(db.usersEntrie).getSingle();
      UserSession.instance.syncFromUser(user);
      addTearDown(UserSession.instance.clear);

      await vocabulary.insertWord(word: '猫', meaning: 'cat');
      await vocabulary.insertWord(word: '犬', meaning: 'dog');
      await vocabulary.insertWord(word: '鳥', meaning: 'bird');
      await vocabulary.insertWord(word: '魚', meaning: 'fish');
      await vocabulary.insertWord(word: '馬', meaning: 'horse');

      final xpCubit = XpCubit(UserRepository(db));
      addTearDown(xpCubit.close);
      cubit = TrainingFeedCubit(
        vocabulary,
        xpCubit,
        CompanionRepository(db),
        TtsService(),
        engine: TrainingFeedEngine(random: Random(11)),
        historyRepository: LearningHistoryRepository(db),
      );
      messages = [];
      final sub = cubit.messageController.listen(messages.add);
      addTearDown(() async {
        // Let pending rewards finish before the database closes.
        await pumpEventQueue();
        await sub.cancel();
        await cubit.close();
      });
      await cubit.load();
    });

    test('revealing a learn card pays nothing', () async {
      final card = await nextCard(TrainingFeedCardType.learn);

      cubit.revealCard(card.id);
      await pumpEventQueue();

      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
      final user = await readUser();
      expect(user.experience, 0);
      expect(user.gems, 0);
    });

    test('a correct quiz answer pays what the card shows', () async {
      final card = await nextCard(TrainingFeedCardType.quiz);

      cubit.answerQuizCard(card.id, card.correctChoiceIndex ?? -1);
      await pumpEventQueue();

      expect(card.xpPreview, greaterThan(0));
      expect(cubit.state.xpEarned, card.xpPreview);
      expect(cubit.state.gemsEarned, card.gemsPreview);
      final user = await readUser();
      expect(user.experience, card.xpPreview);
      expect(user.gems, card.gemsPreview);
    });

    test('a wrong quiz answer pays nothing', () async {
      await answerQuiz(correctly: false);

      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
      expect((await readUser()).experience, 0);
    });

    test('a bonus card cannot be claimed before any quiz was answered',
        () async {
      final bonus = await nextCard(TrainingFeedCardType.reward);

      cubit.claimRewardCard(bonus.id);
      await pumpEventQueue();

      final after = cubit.state.cards.firstWhere((c) => c.id == bonus.id);
      expect(after.isCompleted, isFalse);
      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
      final user = await readUser();
      expect(user.experience, 0);
      expect(user.gems, 0);
      expect(messages.single, contains('3'));
    });

    test('wrong answers do not unlock the bonus', () async {
      for (var i = 0; i < 4; i++) {
        await answerQuiz(correctly: false);
      }

      expect(cubit.state.bonusProgress, 0);
      expect(cubit.state.isBonusUnlocked, isFalse);
    });

    test('three correct answers unlock one bonus card', () async {
      for (var i = 0; i < TrainingFeedState.bonusRequirement; i++) {
        await answerQuiz(correctly: true);
      }
      expect(cubit.state.isBonusUnlocked, isTrue);
      final xpBefore = cubit.state.xpEarned;
      final gemsBefore = cubit.state.gemsEarned;

      final bonus = await nextCard(TrainingFeedCardType.reward);
      cubit.claimRewardCard(bonus.id);
      await pumpEventQueue();

      expect(cubit.state.xpEarned, xpBefore + bonus.xpPreview);
      expect(cubit.state.gemsEarned, gemsBefore + bonus.gemsPreview);
      final user = await readUser();
      expect(user.experience, cubit.state.xpEarned);
      expect(user.gems, cubit.state.gemsEarned);

      // The next bonus has to be earned again.
      expect(cubit.state.bonusProgress, 0);
      final another = await nextCard(TrainingFeedCardType.reward);
      cubit.claimRewardCard(another.id);
      await pumpEventQueue();

      expect(cubit.state.xpEarned, xpBefore + bonus.xpPreview);
      expect(cubit.state.gemsEarned, gemsBefore + bonus.gemsPreview);
    });

    test('a claimed bonus card cannot be claimed twice', () async {
      for (var i = 0; i < TrainingFeedState.bonusRequirement; i++) {
        await answerQuiz(correctly: true);
      }
      final bonus = await nextCard(TrainingFeedCardType.reward);

      cubit.claimRewardCard(bonus.id);
      cubit.claimRewardCard(bonus.id);
      await pumpEventQueue();
      final xpAfterClaim = cubit.state.xpEarned;
      for (var i = 0; i < TrainingFeedState.bonusRequirement; i++) {
        await answerQuiz(correctly: true);
      }
      final xpBeforeSecondTry = cubit.state.xpEarned;
      cubit.claimRewardCard(bonus.id);
      await pumpEventQueue();

      expect(xpAfterClaim, greaterThan(0));
      expect(cubit.state.xpEarned, xpBeforeSecondTry);
      // The unused progress is still there for the next bonus card.
      expect(cubit.state.isBonusUnlocked, isTrue);
    });
  });

  group('engine', () {
    List<VocabularyWithTags> words(int count) => List.generate(count, (i) {
          return VocabularyWithTags(
            word: VocabularyEntry(
              id: i + 1,
              word: 'Word ${i + 1}',
              meaning: 'Meaning ${i + 1}',
              level: 0,
              correctCount: 0,
              wrongCount: 0,
              easeFactor: 2.5,
              repetitions: 0,
              interval: 0,
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            ),
          );
        });

    List<TrainingFeedCard> deal(int wordCount, {int cards = 600, int seed = 3}) {
      final engine = TrainingFeedEngine(random: Random(seed));
      final vocabulary = words(wordCount);
      final dealt = <TrainingFeedCard>[];
      for (var i = 0; i < cards; i++) {
        dealt.add(engine.nextCard(
          vocabulary,
          i,
          previousType: dealt.isNotEmpty ? dealt.last.type : null,
        ));
      }
      return dealt;
    }

    test('with fewer than four words there are no quizzes and no bonuses',
        () {
      for (var wordCount = 1; wordCount < 4; wordCount++) {
        final types = deal(wordCount).map((c) => c.type).toSet();

        expect(
          types.difference(
              {TrainingFeedCardType.learn, TrainingFeedCardType.breakPoint}),
          isEmpty,
          reason: '$wordCount words',
        );
      }
    });

    test('every quiz offers four different answers', () {
      final quizzes = deal(4).where((c) =>
          c.type == TrainingFeedCardType.quiz ||
          c.type == TrainingFeedCardType.audioQuiz);

      expect(quizzes, isNotEmpty);
      for (final quiz in quizzes) {
        expect(quiz.choices.toSet(), hasLength(4));
        expect(quiz.correctChoiceIndex, isNotNull);
      }
    });

    test('learn cards carry no reward', () {
      final learnCards =
          deal(10).where((c) => c.type == TrainingFeedCardType.learn);

      expect(learnCards, isNotEmpty);
      expect(learnCards.every((c) => c.xpPreview == 0 && c.gemsPreview == 0),
          isTrue);
    });

    test('a bonus card always holds XP, gems or both', () {
      final bonuses =
          deal(10, cards: 3000).where((c) => c.type == TrainingFeedCardType.reward);

      expect(bonuses.length, greaterThan(100));
      expect(bonuses.every((c) => c.xpPreview > 0 || c.gemsPreview > 0),
          isTrue);
      expect(bonuses.any((c) => c.xpPreview > 0 && c.gemsPreview == 0), isTrue);
      expect(bonuses.any((c) => c.xpPreview == 0 && c.gemsPreview > 0), isTrue);
      expect(bonuses.any((c) => c.xpPreview > 0 && c.gemsPreview > 0), isTrue);
    });
  });
}
