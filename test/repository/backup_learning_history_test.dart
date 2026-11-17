import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/status_comon.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';

import 'backup_test_support.dart';

void main() {
  final studyDay = DateTime(2026, 3, 1);
  final studyTime = DateTime(2026, 3, 1, 21, 30);

  Future<int> addWord(AppDatabase db, String word, String meaning) {
    return db.into(db.vocabularyEntries).insert(
          VocabularyEntriesCompanion.insert(word: word, meaning: meaning),
        );
  }

  Future<void> answer(
    AppDatabase db,
    String userKey,
    int wordId, {
    bool isCorrect = true,
    String sessionType = SessionType.quiz,
  }) {
    return LearningHistoryRepository(db).recordAnswer(
      userKey: userKey,
      wordId: wordId,
      wordLevelSnapshot: 2,
      sessionType: sessionType,
      isCorrect: isCorrect,
      now: studyTime,
    );
  }

  /// A backup from another device with one correct quiz answer for "neko"
  /// and one wrong test answer for "inu".
  Future<String> backupWithTwoAnswers() async {
    final source = await openDbWithUser('source');
    final neko = await addWord(source, 'neko', 'con mèo');
    final inu = await addWord(source, 'inu', 'con chó');
    await answer(source, 'source', neko);
    await answer(source, 'source', inu,
        isCorrect: false, sessionType: SessionType.test);
    final json = await BackupRepository(source).buildBackupJson();
    await source.close();
    return json;
  }

  Future<int> importInto(AppDatabase db, String json) async {
    final result = await BackupRepository(db).importFromJsonString(json);
    expect(result.success, isTrue, reason: result.error);
    return result.summary?.learningHistoryAdded ?? -1;
  }

  Future<List<LearningHistoryLog>> logs(AppDatabase db) =>
      db.select(db.learningHistoryLogs).get();

  test('a restore on a new device brings the learning history back',
      () async {
    final json = await backupWithTwoAnswers();
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    // Shifts the ids, so the words do not get the ids they had in the file.
    await addWord(target, 'tori', 'con chim');

    final added = await importInto(target, json);

    expect(added, 2);
    final history = LearningHistoryRepository(target);
    // The day is stored as its UTC midnight, whatever the device time zone.
    final activeDay =
        (await history.getActiveDates(userKey: 'target')).single;
    expect(activeDay.isAtSameMomentAs(DateTime.utc(2026, 3, 1)), isTrue);
    final rows = await history.getHistoryByDate(
        userKey: 'target', date: studyDay, pageSize: 10);
    final byWord = {for (final row in rows) row.word: row};
    expect(byWord.keys, unorderedEquals(['neko', 'inu']));
    expect(byWord['neko']?.isCorrect, isTrue);
    expect(byWord['neko']?.sessionType, SessionType.quiz);
    expect(byWord['neko']?.wordLevelSnapshot, 2);
    expect(byWord['inu']?.isCorrect, isFalse);
    expect(byWord['inu']?.sessionType, SessionType.test);
  });

  test('importing the same file twice adds the history once', () async {
    final json = await backupWithTwoAnswers();
    final target = await openDbWithUser('target');
    addTearDown(target.close);

    await importInto(target, json);
    final addedAgain = await importInto(target, json);

    expect(addedAgain, 0);
    expect(await logs(target), hasLength(2));
  });

  test('two identical answers in a file are both restored', () async {
    final source = await openDbWithUser('source');
    final neko = await addWord(source, 'neko', 'con mèo');
    await answer(source, 'source', neko);
    await answer(source, 'source', neko);
    final json = await BackupRepository(source).buildBackupJson();
    await source.close();

    final target = await openDbWithUser('target');
    addTearDown(target.close);
    await importInto(target, json);
    await importInto(target, json);

    expect(await logs(target), hasLength(2));
  });

  test('answers already on the device are kept and not doubled', () async {
    final db = await openDbWithUser('device');
    addTearDown(db.close);
    final neko = await addWord(db, 'neko', 'con mèo');
    await answer(db, 'device', neko);
    final json = await BackupRepository(db).buildBackupJson();
    await answer(db, 'device', neko, isCorrect: false);

    final added = await importInto(db, json);

    expect(added, 0);
    expect(await logs(db), hasLength(2));
  });

  test('an answer for a word that is not in the file is skipped', () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    // Has id 1, the same id the stray answer of the file points at.
    await addWord(target, 'tori', 'con chim');
    final json = jsonEncode({
      'version': 2,
      'vocabularies': [
        {'id': 10, 'word': 'neko', 'meaning': 'con mèo'},
      ],
      'learningHistory': [
        {
          'wordId': 1,
          'wordLevelSnapshot': 0,
          'sessionType': SessionType.feed,
          'isCorrect': true,
          'learnedDate': '2026-03-01T00:00:00.000Z',
          'createdAt': '2026-03-01T14:30:00.000Z',
        },
        {
          'wordId': 10,
          'wordLevelSnapshot': 0,
          'sessionType': SessionType.feed,
          'isCorrect': true,
          'learnedDate': '2026-03-01T00:00:00.000Z',
          'createdAt': '2026-03-01T14:30:00.000Z',
        },
      ],
    });

    final added = await importInto(target, json);

    expect(added, 1);
    final rows = await LearningHistoryRepository(target)
        .getHistoryByDate(userKey: 'target', date: studyDay);
    expect(rows.single.word, 'neko');
  });

  test('a file written before history was backed up changes nothing',
      () async {
    final target = await openDbWithUser('target');
    addTearDown(target.close);
    final neko = await addWord(target, 'neko', 'con mèo');
    await answer(target, 'target', neko);
    final json = jsonEncode({
      'version': 2,
      'vocabularies': [
        {'id': 10, 'word': 'neko', 'meaning': 'con mèo'},
      ],
    });

    await importInto(target, json);

    expect(await logs(target), hasLength(1));
  });
}
