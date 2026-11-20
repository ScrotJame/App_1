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
  final created = DateTime(2026, 11, 19, 9);

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
        now: at ?? created.add(const Duration(minutes: 5)),
      );

  Future<Map<int, LoggedReviewAnswer>> answers({
    DateTime? since,
    List<int>? wordIds,
  }) =>
      history.getDailyReviewAnswers(
        userKey: userKey,
        since: since ?? created,
        wordIds: wordIds ?? [nekoId, inuId, toriId],
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

  test('returns the daily review answers since the review began, by word id',
      () async {
    await log(nekoId, isCorrect: true, level: 3);
    await log(inuId, isCorrect: false, level: 1);

    final found = await answers();

    expect(found.keys, unorderedEquals([nekoId, inuId]));
    expect(found[nekoId]?.isCorrect, isTrue);
    expect(found[nekoId]?.levelBefore, 3);
    expect(found[inuId]?.isCorrect, isFalse);
    expect(found[inuId]?.levelBefore, 1);
  });

  test('ignores other modes, earlier logs, other users and other words',
      () async {
    await db.into(db.usersEntrie).insert(
          UsersEntrieCompanion.insert(keyOpen: 'other', username: 'Other'),
        );
    await log(nekoId, isCorrect: true, sessionType: SessionType.test);
    // Same calendar day, but before the review was created.
    await log(inuId,
        isCorrect: true, at: created.subtract(const Duration(minutes: 1)));
    await log(toriId, isCorrect: true, user: 'other');
    await log(toriId, isCorrect: true);

    expect(await answers(wordIds: [nekoId, inuId]), isEmpty);
  });

  test('a review answered past midnight still finds its answers', () async {
    final lateEvening = DateTime(2026, 11, 19, 23, 50);
    await log(nekoId,
        isCorrect: true, at: lateEvening.add(const Duration(minutes: 20)));

    final found = await answers(since: lateEvening);

    expect(found.keys, [nekoId]);
  });

  test('compares whole seconds, like the createdAt column', () async {
    await log(nekoId,
        isCorrect: true, at: created.add(const Duration(milliseconds: 200)));

    final found =
        await answers(since: created.add(const Duration(milliseconds: 700)));

    expect(found.keys, [nekoId]);
  });

  test('the first answer wins', () async {
    await log(nekoId, isCorrect: false, level: 2);
    await log(nekoId,
        isCorrect: true,
        level: 1,
        at: created.add(const Duration(hours: 1)));

    final found = await answers();

    expect(found[nekoId]?.isCorrect, isFalse);
    expect(found[nekoId]?.levelBefore, 2);
  });

  test('no word ids: nothing to look up', () async {
    await log(nekoId, isCorrect: true);

    expect(await answers(wordIds: const []), isEmpty);
  });
}
