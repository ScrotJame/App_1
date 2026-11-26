import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/models/backup_entity.dart';
import 'package:test_abc/page/backup/backup_cubit.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

class _MockBackupRepository extends Mock implements BackupRepository {}

/// A restore brings back words and their levels, so the review reminder plan
/// has to be built again, but only when the import worked.
void main() {
  setUpAll(() async {
    await S.load(const Locale('vi'));
  });

  late _MockBackupRepository repo;
  late int imported;
  late BackupCubit cubit;

  setUp(() {
    repo = _MockBackupRepository();
    imported = 0;
    cubit = BackupCubit(repo, onImported: () async => imported++);
  });
  tearDown(() => cubit.close());

  test('a successful file import rebuilds the reminder plan', () async {
    when(() => repo.importFromFilePicker())
        .thenAnswer((_) async => const ImportResult.ok(null));

    await cubit.importFromFile();

    expect(cubit.state.status, BackupStatus.success);
    expect(imported, 1);
  });

  test('a failed file import leaves the reminder plan alone', () async {
    when(() => repo.importFromFilePicker())
        .thenAnswer((_) async => const ImportResult.fail('broken file'));

    await cubit.importFromFile();

    expect(cubit.state.status, BackupStatus.failed);
    expect(imported, 0);
  });

  test('a successful server import rebuilds the reminder plan', () async {
    when(() => repo.getBackupKey()).thenAnswer((_) async => 'key');
    when(() => repo.importFromServer(secretKey: 'key'))
        .thenAnswer((_) async => const ImportResult.ok(null));

    await cubit.importFromServer();

    expect(imported, 1);
  });

  test('a failed server import leaves the reminder plan alone', () async {
    when(() => repo.getBackupKey()).thenAnswer((_) async => 'key');
    when(() => repo.importFromServer(secretKey: 'key'))
        .thenAnswer((_) async => const ImportResult.fail('offline'));

    await cubit.importFromServer();

    expect(imported, 0);
  });

  test('a failing rebuild does not turn the import into an error', () async {
    final failing = BackupCubit(
      repo,
      onImported: () async => throw Exception('channel down'),
    );
    addTearDown(failing.close);
    when(() => repo.importFromFilePicker())
        .thenAnswer((_) async => const ImportResult.ok(null));

    await failing.importFromFile();

    expect(failing.state.status, BackupStatus.success);
    expect(failing.state.errorMessage, isNull);
  });
}
