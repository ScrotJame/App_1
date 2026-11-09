import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

import 'backup_test_support.dart';

void main() {
  Future<int> addWord(AppDatabase db, {int? unitId}) {
    return db.into(db.vocabularyEntries).insert(
          VocabularyEntriesCompanion.insert(
            word: 'neko',
            meaning: 'con mèo',
            unitId: Value(unitId),
          ),
        );
  }

  Future<int> addUnit(AppDatabase db, String title) {
    return db.into(db.unitsEntries).insert(
          UnitsEntriesCompanion.insert(title: title),
        );
  }

  test('imports when the device already has duplicate words', () async {
    final source = await openDbWithUser('source');
    await addWord(source);
    final json = await BackupRepository(source).buildBackupJson();

    final target = await openDbWithUser('target');
    await addWord(target);
    await addWord(target);
    final result = await BackupRepository(target).importFromJsonString(json);

    expect(result.success, isTrue, reason: result.error);
    expect(await target.select(target.vocabularyEntries).get(), hasLength(2));
  });

  test('imports when the device already has duplicate unit titles', () async {
    final source = await openDbWithUser('source');
    await addUnit(source, 'Bài 1');
    final json = await BackupRepository(source).buildBackupJson();

    final target = await openDbWithUser('target');
    await addUnit(target, 'Bài 1');
    await addUnit(target, 'Bài 1');
    final result = await BackupRepository(target).importFromJsonString(json);

    expect(result.success, isTrue, reason: result.error);
  });

  test('imports when the device already has duplicate tag names', () async {
    final source = await openDbWithUser('source');
    await source.into(source.tags).insert(TagsCompanion.insert(tagName: 'Trùng'));
    final json = await BackupRepository(source).buildBackupJson();

    final target = await openDbWithUser('target');
    await target.into(target.tags).insert(TagsCompanion.insert(tagName: 'Trùng'));
    await target.into(target.tags).insert(TagsCompanion.insert(tagName: 'Trùng'));
    final result = await BackupRepository(target).importFromJsonString(json);

    expect(result.success, isTrue, reason: result.error);
  });

  test('restores the same word in two units as two rows', () async {
    final source = await openDbWithUser('source');
    await addWord(source, unitId: await addUnit(source, 'Bài 1'));
    await addWord(source, unitId: await addUnit(source, 'Bài 2'));
    final json = await BackupRepository(source).buildBackupJson();

    final target = await openDbWithUser('target');
    final result = await BackupRepository(target).importFromJsonString(json);

    expect(result.success, isTrue, reason: result.error);
    final words = await target.select(target.vocabularyEntries).get();
    expect(words, hasLength(2));
    expect(words.map((w) => w.unitId).toSet(), hasLength(2));
  });
}
