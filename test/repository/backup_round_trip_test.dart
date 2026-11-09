import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

import 'backup_test_support.dart';

void main() {
  final reviewedAt = DateTime(2026, 3, 1, 8);
  final nextReview = DateTime(2026, 3, 13, 8);

  Future<int> insertReviewedWord(AppDatabase db, {DateTime? lastReviewed}) {
    return db.into(db.vocabularyEntries).insert(
          VocabularyEntriesCompanion.insert(
            word: 'neko',
            meaning: 'con mèo',
            easeFactor: const Value(1.7),
            repetitions: const Value(4),
            interval: const Value(12),
            lastReviewed: Value(lastReviewed ?? reviewedAt),
            nextReview: Value(nextReview),
          ),
        );
  }

  test('restores SM-2 schedule on a new device', () async {
    final source = await openDbWithUser('source');
    await insertReviewedWord(source);
    final json = await BackupRepository(source).buildBackupJson();

    final target = await openDbWithUser('target');
    final result = await BackupRepository(target).importFromJsonString(json);

    expect(result.success, isTrue, reason: result.error);
    final word = await target.select(target.vocabularyEntries).getSingle();
    expect(word.easeFactor, 1.7);
    expect(word.repetitions, 4);
    expect(word.interval, 12);
    expect(word.nextReview, nextReview);
  });

  test('uses database defaults when a v1 file has no SM-2 fields', () async {
    final target = await openDbWithUser('target');
    final json = jsonEncode({
      'version': 1,
      'vocabularies': [
        {'id': 1, 'word': 'inu', 'meaning': 'con chó'},
      ],
    });

    final result = await BackupRepository(target).importFromJsonString(json);

    expect(result.success, isTrue, reason: result.error);
    final word = await target.select(target.vocabularyEntries).getSingle();
    expect(word.easeFactor, 2.5);
    expect(word.repetitions, 0);
    expect(word.interval, 0);
  });

  test('takes SM-2 from the file when the file was reviewed later', () async {
    final target = await openDbWithUser('target');
    await insertReviewedWord(target, lastReviewed: DateTime(2026, 2, 1));
    final json = jsonEncode({
      'version': 2,
      'vocabularies': [
        {
          'id': 9,
          'word': 'neko',
          'meaning': 'con mèo',
          'easeFactor': 2.1,
          'repetitions': 7,
          'interval': 30,
          'lastReviewed': reviewedAt.toIso8601String(),
          'nextReview': nextReview.toIso8601String(),
        },
      ],
    });

    await BackupRepository(target).importFromJsonString(json);

    final word = await target.select(target.vocabularyEntries).getSingle();
    expect(word.repetitions, 7);
    expect(word.interval, 30);
    expect(word.lastReviewed, reviewedAt);
  });

  test('keeps local SM-2 when the device was reviewed later', () async {
    final target = await openDbWithUser('target');
    await insertReviewedWord(target);
    final json = jsonEncode({
      'version': 2,
      'vocabularies': [
        {
          'id': 9,
          'word': 'neko',
          'meaning': 'con mèo',
          'easeFactor': 2.5,
          'repetitions': 1,
          'interval': 1,
          'lastReviewed': DateTime(2026, 2, 1).toIso8601String(),
          'updatedAt': DateTime(2030, 1, 1).toIso8601String(),
        },
      ],
    });

    await BackupRepository(target).importFromJsonString(json);

    final word = await target.select(target.vocabularyEntries).getSingle();
    expect(word.repetitions, 4);
    expect(word.lastReviewed, reviewedAt);
    expect(word.nextReview, nextReview);
  });

  test('rejects a backup from a newer format version', () async {
    final target = await openDbWithUser('target');
    final json = jsonEncode({'version': 3, 'vocabularies': []});

    final result = await BackupRepository(target).importFromJsonString(json);

    expect(result.success, isFalse);
  });
}
