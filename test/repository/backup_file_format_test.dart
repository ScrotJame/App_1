import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

import 'backup_test_support.dart';

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('backup_format'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  test('backup content is plain JSON at the current version', () async {
    final db = await openDbWithUser('source');

    final json = await BackupRepository(db).buildBackupJson();

    expect(json.trimLeft().startsWith('{'), isTrue);
    expect(json, contains('"version": 2'));
  });

  test('imports a plain JSON file', () async {
    final source = await openDbWithUser('source');
    final file = File('${tempDir.path}/backup.json')
      ..writeAsStringSync(await BackupRepository(source).buildBackupJson());

    final target = await openDbWithUser('target');
    final result = await BackupRepository(target).importFromFile(file);

    expect(result.success, isTrue, reason: result.error);
  });

  test('rejects a file that is not plain JSON', () async {
    final file = File('${tempDir.path}/backup.json')
      ..writeAsStringSync('aXY=:Y2lwaGVy');

    final target = await openDbWithUser('target');
    final result = await BackupRepository(target).importFromFile(file);

    expect(result.success, isFalse);
    expect(result.error, 'File không phải bản backup JSON của Dungeonary.');
  });
}
