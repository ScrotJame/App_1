import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import 'backup_test_support.dart';

void main() {
  final createdAt = DateTime(2025, 1, 1, 9);
  final lastReviewed = DateTime(2026, 3, 1, 8);
  final nextReview = DateTime(2026, 3, 16, 8);

  late AppDatabase db;
  late VocabularyRepository repo;
  late int unitId;
  late int wordId;

  Future<VocabularyEntry> readWord() {
    return (db.select(db.vocabularyEntries)..where((t) => t.id.equals(wordId)))
        .getSingle();
  }

  setUp(() async {
    db = await openDbWithUser('device');
    addTearDown(db.close);
    repo = VocabularyRepository(db);

    unitId = await db
        .into(db.unitsEntries)
        .insert(UnitsEntriesCompanion.insert(title: 'Unit 1'));
    wordId = await db.into(db.vocabularyEntries).insert(
          VocabularyEntriesCompanion.insert(
            word: '猫',
            meaning: 'cat',
            example: const Value('猫が好きです'),
            pronunciation: const Value('ねこ'),
            language: const Value('ja'),
            level: const Value(4),
            correctCount: const Value(7),
            wrongCount: const Value(2),
            isFavorite: const Value(true),
            lastReviewed: Value(lastReviewed),
            nextReview: Value(nextReview),
            easeFactor: const Value(2.8),
            repetitions: const Value(3),
            interval: const Value(15),
            unitId: Value(unitId),
            createdAt: Value(createdAt),
            updatedAt: Value(createdAt),
          ),
        );
  });

  test('editing a word keeps its learning progress', () async {
    final updated = await repo.updateWord(
      id: wordId,
      word: '猫',
      meaning: 'con mèo',
      pronunciation: 'ねこ',
      language: 'ja',
    );

    expect(updated, isTrue);
    final word = await readWord();
    expect(word.level, 4);
    expect(word.correctCount, 7);
    expect(word.wrongCount, 2);
    expect(word.easeFactor, 2.8);
    expect(word.repetitions, 3);
    expect(word.interval, 15);
    expect(word.lastReviewed, lastReviewed);
    expect(word.nextReview, nextReview);
  });

  test('editing a word keeps the fields the form does not show', () async {
    await repo.updateWord(
      id: wordId,
      word: '猫',
      meaning: 'con mèo',
      pronunciation: 'ねこ',
      language: 'ja',
    );

    final word = await readWord();
    expect(word.example, '猫が好きです');
    expect(word.isFavorite, isTrue);
    expect(word.unitId, unitId);
    expect(word.createdAt, createdAt);
  });

  test('editing a word saves the edited fields and bumps updatedAt', () async {
    await repo.updateWord(
      id: wordId,
      word: '子猫',
      meaning: 'mèo con',
      pronunciation: 'こねこ',
      language: 'ja',
    );

    final word = await readWord();
    expect(word.word, '子猫');
    expect(word.meaning, 'mèo con');
    expect(word.pronunciation, 'こねこ');
    expect(word.language, 'ja');
    expect(word.updatedAt.isAfter(createdAt), isTrue);
  });

  test('an emptied pronunciation is cleared', () async {
    await repo.updateWord(
      id: wordId,
      word: '猫',
      meaning: 'cat',
      pronunciation: null,
      language: 'ja',
    );

    expect((await readWord()).pronunciation, isNull);
  });

  test('returns false and changes nothing for an unknown id', () async {
    final updated = await repo.updateWord(
      id: wordId + 100,
      word: 'x',
      meaning: 'y',
    );

    expect(updated, isFalse);
    expect((await readWord()).meaning, 'cat');
  });
}
