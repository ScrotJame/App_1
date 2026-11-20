import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/daily_review/data/daily_review_local_data_source.dart';
import 'package:test_abc/page/daily_review/data/daily_review_repository.dart';
import 'package:test_abc/page/daily_review/data/daily_review_session.dart';
import 'package:test_abc/page/daily_review/data/daily_review_status.dart';
import 'package:test_abc/page/daily_review/logic/daily_target.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../repository/backup_test_support.dart';

class FakeDailyReviewDataSource implements DailyReviewLocalDataSource {
  final Map<String, String> storage = {};

  @override
  Future<String?> readString(String key) async => storage[key];

  @override
  Future<void> writeString(String key, String value) async {
    storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    storage.remove(key);
  }
}

void main() {
  const userKey = 'device';

  late AppDatabase db;
  late VocabularyRepository vocabulary;
  late LearningHistoryRepository history;
  late FakeDailyReviewDataSource source;
  late DailyReviewRepository repo;
  late DateTime now;

  /// A word learned at [level], reviewed two days before [now].
  Future<int> addLearnedWord(String word, {int level = 1}) async {
    final id = await vocabulary.insertWord(word: word, meaning: 'meaning $word');
    await (db.update(db.vocabularyEntries)..where((t) => t.id.equals(id)))
        .write(VocabularyEntriesCompanion(
      level: Value(level),
      lastReviewed: Value(now.subtract(const Duration(days: 2))),
    ));
    return id;
  }

  Future<DailyReviewSession> open() async {
    final session = await repo.openToday(userKey);
    expect(session, isNotNull);
    return session!;
  }

  Future<DailyReviewSession> answerAll(DailyReviewSession session,
      {required bool isCorrect}) async {
    var current = session;
    for (final id in session.wordIds) {
      current = await repo.saveAnswer(userKey, current,
          wordId: id, isCorrect: isCorrect, level: const LevelStep(1, 1));
    }
    return current;
  }

  setUp(() async {
    now = DateTime(2026, 11, 19, 9);
    db = await openDbWithUser(userKey);
    addTearDown(db.close);
    vocabulary = VocabularyRepository(db);
    history = LearningHistoryRepository(db);
    source = FakeDailyReviewDataSource();
    repo = DailyReviewRepository(source, vocabulary, history,
        clock: () => now, random: Random(7));
    addTearDown(repo.close);
  });

  test('no learned word: no review, nothing stored', () async {
    await vocabulary.insertWord(word: '猫', meaning: 'cat');

    expect(await repo.openToday(userKey), isNull);
    expect(source.storage[DailyReviewRepository.sessionKey(userKey)], isNull);
  });

  test('the first open of the day creates and stores the review', () async {
    final ids = [for (var i = 0; i < 5; i++) await addLearnedWord('w$i')];

    final session = await open();

    expect(session.date, '2026-11-19');
    expect(session.target, DailyTarget.defaultPreset);
    expect(session.adaptive, isFalse);
    expect(session.wordIds.toSet(), ids.toSet());
    expect(
      DailyReviewSession.tryDecode(
          source.storage[DailyReviewRepository.sessionKey(userKey)]),
      session,
    );
  });

  test('the same day resumes the same review with its answers', () async {
    for (var i = 0; i < 5; i++) {
      await addLearnedWord('w$i');
    }
    final first = await open();
    await repo.saveAnswer(userKey, first,
        wordId: first.wordIds.first,
        isCorrect: true,
        level: const LevelStep(1, 2));

    now = now.add(const Duration(hours: 8));
    final again = await open();

    expect(again.wordIds, first.wordIds);
    expect(again.answers, {first.wordIds.first: true});
    expect(again.levels[first.wordIds.first], const LevelStep(1, 2));
  });

  test('a new day creates a new review', () async {
    for (var i = 0; i < 5; i++) {
      await addLearnedWord('w$i');
    }
    final first = await open();
    await repo.saveAnswer(userKey, first,
        wordId: first.wordIds.first,
        isCorrect: true,
        level: const LevelStep(1, 2));

    now = now.add(const Duration(days: 1));
    final next = await open();

    expect(next.date, '2026-11-20');
    expect(next.answers, isEmpty);
  });

  test('broken JSON or another version creates a new review', () async {
    for (var i = 0; i < 3; i++) {
      await addLearnedWord('w$i');
    }
    final key = DailyReviewRepository.sessionKey(userKey);

    source.storage[key] = '{oops';
    final fresh = await open();
    expect(fresh.answers, isEmpty);

    final answered = await repo.saveAnswer(userKey, fresh,
        wordId: fresh.wordIds.first,
        isCorrect: true,
        level: const LevelStep(1, 2));
    source.storage[key] = jsonEncode({...answered.toJson(), 'version': 2});
    expect((await open()).answers, isEmpty);
  });

  test('an answer already logged today is copied, not graded again',
      () async {
    for (var i = 0; i < 3; i++) {
      await addLearnedWord('w$i');
    }
    final session = await open();
    final loggedId = session.wordIds.first;
    final otherModeId = session.wordIds[1];
    // The app died after the database write, before SharedPreferences.
    await history.recordAnswer(
      userKey: userKey,
      wordId: loggedId,
      wordLevelSnapshot: 1,
      sessionType: SessionType.dailyReview,
      isCorrect: false,
      now: now,
    );
    await history.recordAnswer(
      userKey: userKey,
      wordId: otherModeId,
      wordLevelSnapshot: 1,
      sessionType: SessionType.test,
      isCorrect: true,
      now: now,
    );

    final resumed = await open();

    expect(resumed.answers, {loggedId: false});
    expect(resumed.levels[loggedId], const LevelStep(1, 1));
    final word = await (db.select(db.vocabularyEntries)
          ..where((t) => t.id.equals(loggedId)))
        .getSingle();
    expect(word.wrongCount, 1);
  });

  test('a deleted word leaves the review', () async {
    for (var i = 0; i < 3; i++) {
      await addLearnedWord('w$i');
    }
    final session = await open();
    final deleted = session.wordIds.first;
    await vocabulary.deleteWord(deleted);

    final resumed = await open();

    expect(resumed.wordIds, isNot(contains(deleted)));
    expect(resumed.wordIds, hasLength(2));
  });

  test('every word deleted: a new review is made from what is left',
      () async {
    final first = await addLearnedWord('w0');
    await open();
    await vocabulary.deleteWord(first);
    final second = await addLearnedWord('w1');

    final resumed = await open();

    expect(resumed.wordIds, [second]);
  });

  test('completing keeps at most the 3 latest accuracies', () async {
    for (var i = 0; i < 4; i++) {
      await addLearnedWord('w$i');
    }
    for (var day = 0; day < 4; day++) {
      now = DateTime(2026, 11, 19 + day, 9);
      final session = await open();
      final answered = await answerAll(session, isCorrect: day > 0);
      final done = await repo.complete(userKey, answered);
      expect(done.isCompleted, isTrue);
    }

    expect(await repo.readRecentAccuracies(userKey), [1.0, 1.0, 1.0]);
  });

  test('completing twice adds the accuracy once', () async {
    await addLearnedWord('w0');
    final answered = await answerAll(await open(), isCorrect: true);
    final done = await repo.complete(userKey, answered);
    await repo.complete(userKey, done);

    expect(await repo.readRecentAccuracies(userKey), [1.0]);
  });

  test('a new preset only applies to the next review', () async {
    await addLearnedWord('w0');
    expect((await open()).target, 20);

    await repo.savePreset(userKey, 10);
    expect(await repo.readPreset(userKey), 10);
    expect((await open()).target, 20);

    now = now.add(const Duration(days: 1));
    expect((await open()).target, 10);
  });

  test('from 100 learned words the review is adaptive', () async {
    for (var i = 0; i < 100; i++) {
      await addLearnedWord('w$i');
    }

    final session = await open();

    expect(session.adaptive, isTrue);
    expect(session.target, 20);
    expect(session.wordIds, hasLength(20));
    expect(
      AdaptiveTarget.tryDecode(
          source.storage[DailyReviewRepository.adaptiveKey(userKey)]),
      const AdaptiveTarget(value: 20, preset: 20),
    );
  });

  test('the status stream follows today\'s review', () async {
    for (var i = 0; i < 2; i++) {
      await addLearnedWord('w$i');
    }
    final statuses = <DailyReviewStatus>[];
    final sub = repo.watchTodayStatus(userKey).listen(statuses.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    final session = await open();
    final one = await repo.saveAnswer(userKey, session,
        wordId: session.wordIds.first,
        isCorrect: true,
        level: const LevelStep(1, 2));
    final two = await repo.saveAnswer(userKey, one,
        wordId: session.wordIds.last,
        isCorrect: true,
        level: const LevelStep(1, 2));
    await repo.complete(userKey, two);
    await pumpEventQueue();

    expect(statuses, [
      DailyReviewStatus.notCreated,
      const DailyReviewStatus(
          progress: DailyReviewProgress.inProgress, answered: 0, total: 2),
      const DailyReviewStatus(
          progress: DailyReviewProgress.inProgress, answered: 1, total: 2),
      const DailyReviewStatus(
          progress: DailyReviewProgress.inProgress, answered: 2, total: 2),
      const DailyReviewStatus(
          progress: DailyReviewProgress.completed, answered: 2, total: 2),
    ]);
  });

  test('yesterday\'s review reads as not created', () async {
    await addLearnedWord('w0');
    await open();

    now = now.add(const Duration(days: 1));

    expect(await repo.refreshStatus(userKey), DailyReviewStatus.notCreated);
  });
}
