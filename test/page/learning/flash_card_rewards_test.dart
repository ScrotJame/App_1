import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/learning/flash_card/flash_card_cubit.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../../repository/backup_test_support.dart';

/// A flashcard session pays for the cards the learner said they remembered,
/// and one tap rates one card.
void main() {
  const userKey = 'device';

  late AppDatabase db;
  late FlashCardCubit cubit;

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

    cubit = FlashCardCubit(
      vocabulary,
      CompanionRepository(db),
      LearningHistoryRepository(db),
    );
    addTearDown(cubit.close);
    await cubit.start();
  });

  group('rewards', () {
    test('a session rated "again" on every card pays nothing', () async {
      for (var i = 0; i < 4; i++) {
        await cubit.rateCard(DifficultyRating.again);
      }

      expect(cubit.state.status, FlashcardArenaStatus.completed);
      expect(cubit.state.rememberedCount, 0);
      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
    });

    test('only the remembered cards pay', () async {
      await cubit.rateCard(DifficultyRating.again);
      await cubit.rateCard(DifficultyRating.hard);
      await cubit.rateCard(DifficultyRating.good);
      await cubit.rateCard(DifficultyRating.easy);

      expect(cubit.state.status, FlashcardArenaStatus.completed);
      expect(cubit.state.rememberedCount, 3);
      expect(cubit.state.xpEarned, 3 * FlashCardState.xpPerRememberedCard);
      expect(
          cubit.state.gemsEarned, 3 * FlashCardState.gemsPerRememberedCard);
    });

    test('a card skipped with "next" pays nothing', () async {
      cubit.nextCard();
      cubit.nextCard();
      await cubit.rateCard(DifficultyRating.good);
      cubit.nextCard();

      expect(cubit.state.status, FlashcardArenaStatus.completed);
      expect(cubit.state.results, hasLength(1));
      expect(cubit.state.xpEarned, FlashCardState.xpPerRememberedCard);
      expect(cubit.state.gemsEarned, FlashCardState.gemsPerRememberedCard);
    });

    test('a restarted session starts its rewards from zero', () async {
      for (var i = 0; i < 4; i++) {
        await cubit.rateCard(DifficultyRating.easy);
      }
      expect(cubit.state.xpEarned, greaterThan(0));

      await cubit.start();

      expect(cubit.state.results, isEmpty);
      expect(cubit.state.xpEarned, 0);
      expect(cubit.state.gemsEarned, 0);
    });
  });

  group('rating', () {
    test('a double tap rates one card and does not skip the next one',
        () async {
      final firstId = cubit.state.currentCard?.word.id;

      final first = cubit.rateCard(DifficultyRating.good);
      final second = cubit.rateCard(DifficultyRating.good);
      await Future.wait([first, second]);

      expect(cubit.state.currentIndex, 1);
      expect(cubit.state.results, hasLength(1));
      expect(cubit.state.results.single.card.id, firstId.toString());
      expect(await db.select(db.learningHistoryLogs).get(), hasLength(1));
    });

    test('the next card can be rated once it is shown', () async {
      await cubit.rateCard(DifficultyRating.good);
      await cubit.rateCard(DifficultyRating.hard);

      expect(cubit.state.currentIndex, 2);
      expect(cubit.state.results, hasLength(2));
    });

    test('rating after the session ended changes nothing', () async {
      for (var i = 0; i < 4; i++) {
        await cubit.rateCard(DifficultyRating.good);
      }

      await cubit.rateCard(DifficultyRating.good);

      expect(cubit.state.results, hasLength(4));
      expect(await db.select(db.learningHistoryLogs).get(), hasLength(4));
    });
  });
}
