import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import 'backup_test_support.dart';

/// A wrong answer in the daily review lowers the level by one. Status and
/// totalLearned follow the level, as for every other level change.
void main() {
  const userKey = 'device';
  final t0 = DateTime(2026, 11, 19, 9);

  late AppDatabase db;
  late VocabularyRepository repo;
  late int wordId;

  Future<VocabularyEntry> word() =>
      (db.select(db.vocabularyEntries)..where((t) => t.id.equals(wordId)))
          .getSingle();

  Future<int?> status() async => (await (db.select(db.userWordProgressEntrie)
            ..where((t) => t.wordId.equals(wordId)))
          .getSingleOrNull())
      ?.status;

  Future<int> totalLearned() async =>
      (await db.select(db.usersEntrie).getSingle()).totalLearned;

  Future<void> setLevel(int level, DateTime lastReviewed) =>
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

  test('5 → 4: the word is no longer mastered and totalLearned drops',
      () async {
    await repo.markWordMastered(wordId, userKey, now: t0);
    expect(await totalLearned(), 1);
    final later = t0.add(const Duration(days: 1));

    final change = await repo.levelDown(wordId, userKey, now: later);

    expect(change?.previousLevel, 5);
    expect(change?.word.level, 4);
    expect(change?.leveledDown, isTrue);
    expect(change?.leveledUp, isFalse);
    expect((await word()).lastReviewed, later);
    expect(await status(), WordStatus.learning);
    expect(await totalLearned(), 0);
  });

  test('3 → 2 restarts the wait', () async {
    await setLevel(3, t0);
    final later = t0.add(const Duration(hours: 5));

    final change = await repo.levelDown(wordId, userKey, now: later);

    expect(change?.word.level, 2);
    expect((await word()).lastReviewed, later);
    expect(await totalLearned(), 0);
  });

  test('level 0 stays 0 but lastReviewed moves to the answer', () async {
    await setLevel(0, t0);
    final later = t0.add(const Duration(hours: 1));

    final change = await repo.levelDown(wordId, userKey, now: later);

    expect(change?.previousLevel, 0);
    expect(change?.word.level, 0);
    expect(change?.leveledDown, isFalse);
    expect((await word()).lastReviewed, later);
    expect(await status(), WordStatus.notStarted);
  });

  test('an unknown word returns null', () async {
    expect(await repo.levelDown(9999, userKey, now: t0), isNull);
  });
}
