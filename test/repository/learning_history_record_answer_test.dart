import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import 'backup_test_support.dart';

void main() {
  const userKey = 'device';
  final answeredAt = DateTime(2026, 3, 10, 21, 30);

  late AppDatabase db;
  late LearningHistoryRepository history;
  late int nekoId;
  late int inuId;

  Future<VocabularyEntry> word(int id) =>
      (db.select(db.vocabularyEntries)..where((t) => t.id.equals(id)))
          .getSingle();

  Future<List<LearningHistoryLog>> logs() =>
      db.select(db.learningHistoryLogs).get();

  Future<void> answer(
    int wordId, {
    required bool isCorrect,
    String sessionType = SessionType.feed,
    String user = userKey,
    int level = 0,
  }) =>
      history.recordAnswer(
        userKey: user,
        wordId: wordId,
        wordLevelSnapshot: level,
        sessionType: sessionType,
        isCorrect: isCorrect,
        now: answeredAt,
      );

  setUp(() async {
    db = await openDbWithUser(userKey);
    addTearDown(db.close);
    history = LearningHistoryRepository(db);
    final vocabulary = VocabularyRepository(db);
    nekoId = await vocabulary.insertWord(word: '猫', meaning: 'cat');
    inuId = await vocabulary.insertWord(word: '犬', meaning: 'dog');
  });

  group('counters', () {
    test('a correct answer raises only the correct counter', () async {
      await answer(nekoId, isCorrect: true);

      final neko = await word(nekoId);
      expect(neko.correctCount, 1);
      expect(neko.wrongCount, 0);
    });

    test('a wrong answer raises only the wrong counter', () async {
      await answer(nekoId, isCorrect: false);

      final neko = await word(nekoId);
      expect(neko.correctCount, 0);
      expect(neko.wrongCount, 1);
    });

    test('other words are not touched', () async {
      await answer(nekoId, isCorrect: true);
      await answer(nekoId, isCorrect: false);

      final inu = await word(inuId);
      expect(inu.correctCount, 0);
      expect(inu.wrongCount, 0);
    });

    test('answers recorded at the same time are all counted', () async {
      await Future.wait([
        for (var i = 0; i < 12; i++) answer(nekoId, isCorrect: i.isEven),
      ]);

      final neko = await word(nekoId);
      expect(neko.correctCount, 6);
      expect(neko.wrongCount, 6);
      expect(await logs(), hasLength(12));
    });

    test('level, review schedule and edit time stay as they were', () async {
      final nextReview = DateTime(2026, 3, 20);
      final editedAt = DateTime(2026, 2, 1);
      await (db.update(db.vocabularyEntries)
            ..where((t) => t.id.equals(nekoId)))
          .write(VocabularyEntriesCompanion(
        level: const Value(3),
        easeFactor: const Value(2.1),
        repetitions: const Value(4),
        interval: const Value(9),
        nextReview: Value(nextReview),
        updatedAt: Value(editedAt),
      ));

      await answer(nekoId, isCorrect: true);
      await answer(nekoId, isCorrect: false);

      final neko = await word(nekoId);
      expect(neko.level, 3);
      expect(neko.easeFactor, 2.1);
      expect(neko.repetitions, 4);
      expect(neko.interval, 9);
      expect(neko.nextReview, nextReview);
      expect(neko.updatedAt, editedAt);
    });
  });

  group('history', () {
    test('each answer adds a row with its mode, level and result', () async {
      await answer(nekoId,
          isCorrect: true, sessionType: SessionType.quiz, level: 2);
      await answer(inuId,
          isCorrect: false, sessionType: SessionType.matching, level: 0);

      final rows = await logs();
      expect(rows, hasLength(2));
      expect(rows[0].userKey, userKey);
      expect(rows[0].wordId, nekoId);
      expect(rows[0].sessionType, 'Quiz');
      expect(rows[0].wordLevelSnapshot, 2);
      expect(rows[0].isCorrect, isTrue);
      expect(rows[1].wordId, inuId);
      expect(rows[1].sessionType, 'Matching');
      expect(rows[1].isCorrect, isFalse);
    });

    test('the day of the answer becomes an active day', () async {
      await answer(nekoId, isCorrect: true);

      final activeDays = await history.getActiveDates(userKey: userKey);

      expect(activeDays, hasLength(1));
      expect(activeDays.single.toUtc(), DateTime.utc(2026, 3, 10));
    });

    test('the answer shows up in the history of that day', () async {
      await answer(nekoId, isCorrect: true, sessionType: SessionType.feed);

      final day = await history.getHistoryByDate(
        userKey: userKey,
        date: answeredAt,
      );
      final otherDay = await history.getHistoryByDate(
        userKey: userKey,
        date: answeredAt.add(const Duration(days: 1)),
      );

      expect(day, hasLength(1));
      expect(day.single.word, '猫');
      expect(day.single.sessionType, 'Feed');
      expect(day.single.isCorrect, isTrue);
      expect(otherDay, isEmpty);
      expect(
        await history.getHistoryCountByDate(userKey: userKey, date: answeredAt),
        1,
      );
    });
  });

  group('missing data', () {
    test('an unknown word records nothing', () async {
      await answer(9999, isCorrect: true);

      expect(await logs(), isEmpty);
    });

    test('without a user only the counter is updated', () async {
      await answer(nekoId, isCorrect: true, user: '');

      expect((await word(nekoId)).correctCount, 1);
      expect(await logs(), isEmpty);
    });

    test('a failed history row does not leave a half-recorded answer',
        () async {
      // The history row references a user that does not exist.
      await expectLater(
        answer(nekoId, isCorrect: true, user: 'someone-else'),
        throwsA(anything),
      );

      expect((await word(nekoId)).correctCount, 0);
      expect(await logs(), isEmpty);
    });
  });
}
