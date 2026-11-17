import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import 'backup_test_support.dart';

/// A word's `level` is the only progress measure. The user's status row and
/// `totalLearned` are derived from it and must never drift away from it.
void main() {
  const userKey = 'device';
  final t0 = DateTime(2026, 3, 10, 9);

  late AppDatabase db;
  late VocabularyRepository repo;
  late int wordId;

  Future<VocabularyEntry> word([int? id]) =>
      (db.select(db.vocabularyEntries)..where((t) => t.id.equals(id ?? wordId)))
          .getSingle();

  Future<UserWordProgressEntrieData?> progress([int? id]) =>
      (db.select(db.userWordProgressEntrie)
            ..where((t) => t.wordId.equals(id ?? wordId)))
          .getSingleOrNull();

  Future<int> totalLearned() async =>
      (await db.select(db.usersEntrie).getSingle()).totalLearned;

  Future<void> setLevel(int level, {DateTime? lastReviewed}) =>
      (db.update(db.vocabularyEntries)..where((t) => t.id.equals(wordId)))
          .write(VocabularyEntriesCompanion(
        level: Value(level),
        lastReviewed: Value(lastReviewed),
      ));

  setUp(() async {
    db = await openDbWithUser(userKey);
    addTearDown(db.close);
    repo = VocabularyRepository(db);
    wordId = await repo.insertWord(word: '猫', meaning: 'cat');
  });

  group('levelUpIfDue', () {
    test('a word that was never reviewed levels up at once', () async {
      final change = await repo.levelUpIfDue(wordId, userKey, now: t0);

      expect(change?.leveledUp, isTrue);
      expect(change?.previousLevel, 0);
      expect(change?.word.level, 1);
      final stored = await word();
      expect(stored.level, 1);
      expect(stored.lastReviewed, t0);
    });

    test('a second correct answer right away does not count', () async {
      await repo.levelUpIfDue(wordId, userKey, now: t0);

      final change = await repo.levelUpIfDue(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 1)),
      );

      expect(change?.leveledUp, isFalse);
      final stored = await word();
      expect(stored.level, 1);
      expect(stored.lastReviewed, t0, reason: 'the wait must not move');
    });

    test('it counts again once the word has rested', () async {
      await repo.levelUpIfDue(wordId, userKey, now: t0);

      // Level 1 rests for 15 minutes.
      final early = await repo.levelUpIfDue(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 14, seconds: 59)),
      );
      final onTime = await repo.levelUpIfDue(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 15)),
      );

      expect(early?.leveledUp, isFalse);
      expect(onTime?.leveledUp, isTrue);
      expect((await word()).level, 2);
    });

    test('five correct answers in a row do not master a word', () async {
      for (var i = 0; i < 5; i++) {
        await repo.levelUpIfDue(
          wordId,
          userKey,
          now: t0.add(Duration(seconds: 30 * i)),
        );
      }

      expect((await word()).level, 1);
      expect((await progress())?.status, WordStatus.learning);
      expect(await totalLearned(), 0);
    });

    test('reaching the mastered level counts the word once', () async {
      await setLevel(4, lastReviewed: t0);

      final change = await repo.levelUpIfDue(
        wordId,
        userKey,
        now: t0.add(const Duration(hours: 2)),
      );

      expect(change?.word.level, WordStatus.masteredLevel);
      expect((await progress())?.status, WordStatus.mastered);
      expect(await totalLearned(), 1);

      // A later review of a mastered word is not a new word learned.
      await repo.levelUpIfDue(
        wordId,
        userKey,
        now: t0.add(const Duration(days: 20)),
      );
      expect((await word()).level, 6);
      expect(await totalLearned(), 1);
    });

    test('an unknown word changes nothing', () async {
      final change = await repo.levelUpIfDue(99999, userKey, now: t0);

      expect(change, isNull);
      expect(await db.select(db.userWordProgressEntrie).get(), isEmpty);
      expect(await totalLearned(), 0);
    });

    test('the old schedule columns are left alone', () async {
      await repo.levelUpIfDue(wordId, userKey, now: t0);

      final stored = await word();
      expect(stored.nextReview, isNull);
      expect(stored.repetitions, 0);
      expect(stored.interval, 0);
      expect(stored.easeFactor, 2.5);
    });
  });

  group('restartReviewWait', () {
    test('a wrong answer keeps the level and writes the status row', () async {
      await setLevel(3, lastReviewed: t0);
      final at = t0.add(const Duration(hours: 3));

      final change = await repo.restartReviewWait(wordId, userKey, now: at);

      expect(change?.leveledUp, isFalse);
      final stored = await word();
      expect(stored.level, 3);
      expect(stored.lastReviewed, at);
      expect((await progress())?.status, WordStatus.learning);
      expect((await progress())?.lastPracticed, at);
    });

    test('retaking the test right after a wrong answer does not level up',
        () async {
      await repo.restartReviewWait(wordId, userKey, now: t0);

      final retake = await repo.levelUpIfDue(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 1)),
      );
      final later = await repo.levelUpIfDue(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 5)),
      );

      expect(retake?.leveledUp, isFalse);
      expect(later?.leveledUp, isTrue);
    });
  });

  group('markWordMastered', () {
    test('lifts the word to the mastered level and counts it', () async {
      final change = await repo.markWordMastered(wordId, userKey, now: t0);

      expect(change?.word.level, WordStatus.masteredLevel);
      expect((await word()).lastReviewed, t0);
      expect((await progress())?.status, WordStatus.mastered);
      expect(await repo.isWordAlreadyMastered(wordId, userKey), isTrue);
      expect(await totalLearned(), 1);
    });

    test('marking the same word again is not counted twice', () async {
      await repo.markWordMastered(wordId, userKey, now: t0);
      await repo.markWordMastered(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 1)),
      );

      expect(await totalLearned(), 1);
      expect((await word()).lastReviewed, t0);
    });

    test('two taps at the same time count once', () async {
      await Future.wait([
        repo.markWordMastered(wordId, userKey),
        repo.markWordMastered(wordId, userKey),
        repo.markWordMastered(wordId, userKey),
      ]);

      expect(await totalLearned(), 1);
    });

    test('a level above mastered is not pulled down', () async {
      await setLevel(7, lastReviewed: t0);

      await repo.markWordMastered(wordId, userKey);

      expect((await word()).level, 7);
      expect(await totalLearned(), 0, reason: 'it was mastered already');
    });
  });

  group('returnWordToReview', () {
    test('takes a mastered word back to learning and uncounts it', () async {
      await repo.markWordMastered(wordId, userKey, now: t0);

      final change = await repo.returnWordToReview(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 1)),
      );

      expect(change?.word.level, WordStatus.masteredLevel - 1);
      expect((await progress())?.status, WordStatus.learning);
      expect(await repo.isWordAlreadyMastered(wordId, userKey), isFalse);
      expect(await totalLearned(), 0);
    });

    test('mastering the word again does not count it twice', () async {
      await repo.markWordMastered(wordId, userKey, now: t0);
      final demotedAt = t0.add(const Duration(minutes: 1));
      await repo.returnWordToReview(wordId, userKey, now: demotedAt);

      await repo.levelUpIfDue(
        wordId,
        userKey,
        now: demotedAt.add(const Duration(hours: 2)),
      );

      expect((await word()).level, WordStatus.masteredLevel);
      expect(await totalLearned(), 1);
    });

    test('a word still in learning keeps its level', () async {
      await setLevel(2, lastReviewed: t0);

      await repo.returnWordToReview(
        wordId,
        userKey,
        now: t0.add(const Duration(minutes: 1)),
      );

      final stored = await word();
      expect(stored.level, 2);
      expect(stored.lastReviewed, t0);
      expect((await progress())?.status, WordStatus.learning);
      expect(await totalLearned(), 0);
    });

    test('the counter never goes below zero', () async {
      // Mastered in the data, but the counter was never raised for it.
      await setLevel(5, lastReviewed: t0);

      await repo.returnWordToReview(wordId, userKey);

      expect(await totalLearned(), 0);
    });
  });

  test('the status row always matches the level', () async {
    var now = t0;
    Future<void> check() async {
      final stored = await word();
      expect((await progress())?.status, WordStatus.fromLevel(stored.level),
          reason: 'level ${stored.level}');
    }

    await repo.restartReviewWait(wordId, userKey, now: now);
    await check();
    for (var i = 0; i < 6; i++) {
      now = now.add(const Duration(days: 9));
      await repo.levelUpIfDue(wordId, userKey, now: now);
      await check();
    }
    await repo.returnWordToReview(wordId, userKey, now: now);
    await check();
    await repo.markWordMastered(wordId, userKey, now: now);
    await check();
  });

  group('nextReviewReminderTime', () {
    test('is null while no word has been reviewed', () async {
      expect(await repo.nextReviewReminderTime(now: t0), isNull);
    });

    test('is the moment the earliest reviewed word becomes due', () async {
      final other = await repo.insertWord(word: '犬', meaning: 'dog');
      await repo.levelUpIfDue(wordId, userKey, now: t0); // level 1: +15 min
      await repo.restartReviewWait(other, userKey, now: t0); // level 0: +5 min

      expect(
        await repo.nextReviewReminderTime(now: t0),
        t0.add(const Duration(minutes: 5)),
      );
    });

    test('skips words that are due already', () async {
      final other = await repo.insertWord(word: '犬', meaning: 'dog');
      await repo.levelUpIfDue(wordId, userKey, now: t0); // due 09:15
      await repo.restartReviewWait(other, userKey, now: t0); // due 09:05

      expect(
        await repo.nextReviewReminderTime(
          now: t0.add(const Duration(minutes: 10)),
        ),
        t0.add(const Duration(minutes: 15)),
      );
      expect(
        await repo.nextReviewReminderTime(
          now: t0.add(const Duration(minutes: 20)),
        ),
        isNull,
      );
    });

    test('forgets a word once it is deleted', () async {
      await repo.levelUpIfDue(wordId, userKey, now: t0);

      await repo.deleteWord(wordId);

      expect(await repo.nextReviewReminderTime(now: t0), isNull);
    });
  });
}
