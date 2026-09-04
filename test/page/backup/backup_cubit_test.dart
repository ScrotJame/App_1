import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/models/backup_entity.dart';
import 'package:test_abc/page/backup/backup_cubit.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late BackupCubit cubit;
  late MockBackupRepository mockRepo;

  setUp(() {
    mockRepo = MockBackupRepository();
    cubit = BackupCubit(mockRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('BackupCubit - exportToServer', () {
    blocTest<BackupCubit, BackupState>(
      'emits [loading, success] khi exportToServer thành công',
      build: () {
        when(() => mockRepo.getBackupKey()).thenAnswer((_) async => 'yFnfG2BftCYkkqBK5Bk8lhqjFm73');
        when(() => mockRepo.exportToServer(secretKey: 'yFnfG2BftCYkkqBK5Bk8lhqjFm73'))
            .thenAnswer((_) async => const ExportResult.ok());
        return cubit;
      },
      act: (cubit) => cubit.exportToServer(),
      expect: () => const [
        BackupState(status: BackupStatus.loading),
        BackupState(
          status: BackupStatus.success,
          successMessage: 'Đã upload backup lên cloud!',
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'emits [failed] khi backup key trả về null',
      build: () {
        when(() => mockRepo.getBackupKey()).thenAnswer((_) async => null);
        return cubit;
      },
      act: (cubit) => cubit.exportToServer(),
      expect: () => const [
        BackupState(
          status: BackupStatus.failed,
          errorMessage: 'Không lấy được backup key. Vui lòng đăng nhập hoặc nhập key.',
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'emits [failed] khi backup key là chuỗi rỗng',
      build: () {
        when(() => mockRepo.getBackupKey()).thenAnswer((_) async => '');
        return cubit;
      },
      act: (cubit) => cubit.exportToServer(),
      expect: () => const [
        BackupState(
          status: BackupStatus.failed,
          errorMessage: 'Không lấy được backup key. Vui lòng đăng nhập hoặc nhập key.',
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'emits [loading, failed] khi exportToServer gặp lỗi từ repository',
      build: () {
        when(() => mockRepo.getBackupKey()).thenAnswer((_) async => 'yFnfG2BftCYkkqBK5Bk8lhqjFm73');
        when(() => mockRepo.exportToServer(secretKey: 'yFnfG2BftCYkkqBK5Bk8lhqjFm73'))
            .thenAnswer((_) async => const ExportResult.fail('Network error'));
        return cubit;
      },
      act: (cubit) => cubit.exportToServer(),
      expect: () => const [
        BackupState(status: BackupStatus.loading),
        BackupState(
          status: BackupStatus.failed,
          errorMessage: 'Network error',
        ),
      ],
    );
  });
}
