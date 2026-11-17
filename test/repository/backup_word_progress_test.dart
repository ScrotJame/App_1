import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import 'backup_test_support.dart';

void main() {
  final localEdit = DateTime(2026, 5, 1);

  Future<int> addWord(
    AppDatabase db, {
    String word = 'neko',
    String meaning = 'con mèo',
    int level = 0,
    int correctCount = 0,
    int wrongCount = 0,
  }) {
    return db.into(db.vocabularyEntries).insert(
          VocabularyEntriesCompanion.insert(
            word: word,
            meaning: meaning,
            level: Value(level),
            correctCount: Value(correctCount),
            wrongCount: Value(wrongCount),
            updatedAt: Value(localEdit),
          ),
        );
  }

  Future<void> addStatusRow(
    AppDatabase db,
    String userKey,
    int wordId,
    int status,
  ) {
    return db.into(db.userWordProgressEntrie).insert(
          UserWordProgressEntrieCompanion.insert(
            userId: userKey,
            wordId: wordId,
            status: Value(status),
            updatedAt: Value(localEdit),
          ),
        );
  }

  /// A backup holding the word "neko" with id 10.
  String fileWithNeko({
    int level = 0,
    int correctCount = 0,
    int wrongCount = 0,
    DateTime? updatedAt,
    List<Map<String, dynamic>> wordProgress = const [],
  }) {
    return jsonEncode({
      'version': 2,
      'vocabularies': [
        {
          'id': 10,
          'word': 'neko',
          'meaning': 'con mèo',
          'level': level,
          'correctCount': correctCount,
          'wrongCount': wrongCount,
          'updatedAt': updatedAt?.toIso8601String(),
        },
      ],
      'wordProgress': wordProgress,
    });
  }

  Future<void> importInto(AppDatabase db, String json) async {
    final result = await BackupRepository(db).importFromJsonString(json);
    expect(result.success, isTrue, reason: result.error);
  }

  Future<VocabularyEntry> wordNamed(AppDatabase db, String word) {
    return (db.select(db.vocabularyEntries)
          ..where((t) => t.word.equals(word)))
        .getSingle();
  }

  Future<List<UserWordProgressEntrieData>> statusRows(AppDatabase db) =>
      db.select(db.userWordProgressEntrie).get();

  group('answer counters', () {
    test('a file edited later does not lower them', () async {
      final target = await openDbWithUser('target');
      addTearDown(target.close);
      await addWord(target, correctCount: 9, wrongCount: 4);

      await importInto(
        target,
        fileWithNeko(
          correctCount: 2,
          wrongCount: 7,
          updatedAt: DateTime(2030, 1, 1),
        ),
      );

      final word = await wordNamed(target, 'neko');
      expect(word.correctCount, 9);
      expect(word.wrongCount, 7);
    });

    test('higher counters come from a file that was not edited later',
        () async {
      final target = await openDbWithUser('target');
      addTearDown(target.close);
      await addWord(target, correctCount: 1, wrongCount: 1);

      await importInto(
        target,
        fileWithNeko(
          correctCount: 6,
          wrongCount: 3,
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final word = await wordNamed(target, 'neko');
      expect(word.correctCount, 6);
      expect(word.wrongCount, 3);
      expect(word.updatedAt, localEdit);
    });
  });

  group('level', () {
    test('a higher level comes from a file that was not edited later',
        () async {
      final target = await openDbWithUser('target');
      addTearDown(target.close);
      await addWord(target, level: 1);

      await importInto(
        target,
        fileWithNeko(level: 4, updatedAt: DateTime(2026, 1, 1)),
      );

      expect((await wordNamed(target, 'neko')).level, 4);
    });

    test('a file edited later does not lower the level', () async {
      final target = await openDbWithUser('target');
      addTearDown(target.close);
      await addWord(target, level: 5);

      await importInto(
        target,
        fileWithNeko(level: 2, updatedAt: DateTime(2030, 1, 1)),
      );

      expect((await wordNamed(target, 'neko')).level, 5);
    });

    test('the status row on the device follows a level raised by the file',
        () async {
      final target = await openDbWithUser('target');
      addTearDown(target.close);
      final wordId = await addWord(target, level: 1);
      await addStatusRow(target, 'target', wordId, WordStatus.learning);

      await importInto(target, fileWithNeko(level: 5));

      expect((await statusRows(target)).single.status, WordStatus.mastered);
    });

    test('a status row from the file is not left below the merged level',
        () async {
      final target = await openDbWithUser('target');
      addTearDown(target.close);
      final wordId = await addWord(target, level: 5);
      await addStatusRow(target, 'target', wordId, WordStatus.mastered);

      await importInto(
        target,
        fileWithNeko(
          level: 2,
          wordProgress: [
            {
              'wordId': 10,
              'status': WordStatus.learning,
              'updatedAt': DateTime(2030, 1, 1).toIso8601String(),
            },
          ],
        ),
      );

      expect((await wordNamed(target, 'neko')).level, 5);
      expect((await statusRows(target)).single.status, WordStatus.mastered);
    });

    test('a mastered word is restored as mastered on a new device', () async {
      final source = await openDbWithUser('source');
      final sourceWordId = await addWord(source);
      await VocabularyRepository(source)
          .markWordMastered(sourceWordId, 'source');
      final json = await BackupRepository(source).buildBackupJson();
      await source.close();

      final target = await openDbWithUser('target');
      addTearDown(target.close);
      // Shifts the ids, so the word does not get the id it had in the file.
      await addWord(target, word: 'inu', meaning: 'con chó');
      await importInto(target, json);

      final word = await wordNamed(target, 'neko');
      expect(word.level, WordStatus.masteredLevel);
      final row = (await statusRows(target)).single;
      expect(row.userId, 'target');
      expect(row.wordId, word.id);
      expect(row.status, WordStatus.mastered);
      expect(
        await VocabularyRepository(target)
            .isWordAlreadyMastered(word.id, 'target'),
        isTrue,
      );
    });
  });

  group('status rows that cannot be placed', () {
    test('a row for a word that is not in the file is skipped', () async {
      final target = await openDbWithUser('target');
      addTearDown(target.close);
      // Has id 1, the same id the stray row of the file points at.
      final inuId = await addWord(target, word: 'inu', meaning: 'con chó');

      final result = await BackupRepository(target).importFromJsonString(
        fileWithNeko(
          wordProgress: [
            {
              'wordId': inuId,
              'status': WordStatus.mastered,
              'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
            },
            {
              'wordId': 999,
              'status': WordStatus.mastered,
              'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
            },
          ],
        ),
      );

      expect(result.success, isTrue, reason: result.error);
      expect(await statusRows(target), isEmpty);
      // The rest of the file is still imported.
      expect((await wordNamed(target, 'neko')).meaning, 'con mèo');
    });

    test('a file without a user still imports on a device without one',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(target.close);

      final result = await BackupRepository(target).importFromJsonString(
        jsonEncode({
          'version': 2,
          'vocabularies': [
            {'id': 10, 'word': 'neko', 'meaning': 'con mèo'},
          ],
          'wordProgress': [
            {
              'wordId': 10,
              'status': WordStatus.learning,
              'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
            },
          ],
          'activities': [
            {
              'activityDate': DateTime(2026, 1, 1).toIso8601String(),
              'createdAt': DateTime(2026, 1, 1).toIso8601String(),
            },
          ],
        }),
      );

      expect(result.success, isTrue, reason: result.error);
      expect((await wordNamed(target, 'neko')).meaning, 'con mèo');
      expect(await statusRows(target), isEmpty);
    });
  });
}
