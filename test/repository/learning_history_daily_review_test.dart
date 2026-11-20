import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import 'backup_test_support.dart';

/// The daily review reads its own logs back to recover answers that reached
/// the database but not SharedPreferences.
void main() {
  const userKey = 'device';
  final day = DateTime(2026, 11, 19, 9);

  late AppDatabase db;
  late LearningHistoryRepository history;
  late int nekoId;
  late int inuId;
  late int toriId;

  Future<void> log(
    int wordId, {
    required bool isCorrect,
    String sessionType = SessionType.dailyReview,
    DateTime? at,
    int level = 2,
    String user = userKey,
  }) =>
      history.recordAnswer(
        userKey: user,
        wordId: wordId,
        wordLevelSnapshot: level,
        sessionType: sessionType,
        isCorrect: isCorrect,
        now: at ?? day,
      );

  setUp(() async {
    db = await openDbWithUser(userKey);
    addTearDown(db.close);
    history = LearningHistoryRepository(db);
    final vocabulary = VocabularyRepository(db);
    nekoId = await vocabulary.insertWord(word: '猫', meaning: 'cat');
    inuId = await vocabulary.insertWord(word: '犬', meaning: 'dog');
    toriId = await vocabulary.insertWord(word: '鳥', meaning: 'bird');
  });

  test('returns the daily review answers of the day by word id', () async {
    await log(nekoId, isCorrect: true, level: 3);
    await log(inuId, isCorrect: false, level: 1);

    final answers =
        await history.getDailyReviewAnswers(userKey: userKey, day: day);

    expect(answers.keys, unorderedEquals([nekoId, inuId]));
    expect(answers[nekoId]?.isCorrect, isTrue);
    expect(answers[nekoId]?.levelBefore, 3);
    expect(answers[inuId]?.isCorrect, isFalse);
    expect(answers[inuId]?.levelBefore, 1);
  });

  test('ignores other modes, other days and other users', () async {
    await db.into(db.usersEntrie).insert(
          UsersEntrieCompanion.insert(keyOpen: 'other', username: 'Other'),
        );
    await log(nekoId, isCorrect: true, sessionType: SessionType.test);
    await log(inuId,
        isCorrect: true, at: day.subtract(const Duration(days: 1)));
    await log(toriId, isCorrect: true, user: 'other');

    expect(
      await history.getDailyReviewAnswers(userKey: userKey, day: day),
      isEmpty,
    );
  });

  test('the first answer of the day wins', () async {
    await log(nekoId, isCorrect: false, level: 2);
    await log(nekoId,
        isCorrect: true, level: 1, at: day.add(const Duration(hours: 1)));

    final answers =
        await history.getDailyReviewAnswers(userKey: userKey, day: day);

    expect(answers[nekoId]?.isCorrect, isFalse);
    expect(answers[nekoId]?.levelBefore, 2);
  });
}
