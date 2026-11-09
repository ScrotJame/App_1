import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/models/backup_entity.dart';
import 'package:test_abc/page/backup/backup_cubit.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

class _MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late _MockBackupRepository repo;
  late BackupCubit cubit;

  setUp(() {
    repo = _MockBackupRepository();
    cubit = BackupCubit(repo);
  });
  tearDown(() => cubit.close());

  test('cancelling the save dialog shows neither success nor error', () async {
    when(() => repo.exportToFile())
        .thenAnswer((_) async => const ExportResult.cancelled());

    await cubit.exportToFile();

    expect(cubit.state.status, BackupStatus.initial);
    expect(cubit.state.successMessage, isNull);
    expect(cubit.state.errorMessage, isNull);
  });

  test('a saved file reports success without naming a folder', () async {
    when(() => repo.exportToFile())
        .thenAnswer((_) async => const ExportResult.ok(filePath: 'x.json'));

    await cubit.exportToFile();

    expect(cubit.state.status, BackupStatus.success);
    expect(cubit.state.successMessage, 'Đã lưu file backup!');
  });
}
