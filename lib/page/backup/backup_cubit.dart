import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/backup_entity.dart';
import '../../repository/backup_data_repository.dart';

part 'backup_state.dart';

class BackupCubit extends Cubit<BackupState> {
  final BackupRepository _repo;

  BackupCubit(this._repo) : super(const BackupState());

  // ─── Mode toggle ──────────────────────────────────────────────────────────

  void setMode(BackupMode mode) {
    emit(state.copyWith(mode: mode));
  }

  Future<void> loadBackupKey() async {
    final key = await _repo.getBackupKey();
    if (key != null) {
      emit(state.copyWith(backupKey: key));
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: 'Chưa có backup key. Vui lòng thử lại sau.',
      ));
    }
  }

  Future<void> exportAndShare() async {
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.exportAndShare();
    if (result.success) {
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: 'Đã xuất file backup thành công!',
      ));
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: result.error,
      ));
    }
  }

  Future<void> exportToFile() async {
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.exportToFile();
    if (result.success) {
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: 'Đã lưu file vào thư mục Downloads!',
        exportedFilePath: result.filePath,
      ));
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: result.error,
      ));
    }
  }

  Future<void> exportToServer({String? backupKey}) async {
    final key = backupKey ?? state.backupKey ?? await _repo.getBackupKey();
    if (key == null || key.isEmpty) {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: 'Không lấy được backup key. Vui lòng đăng nhập hoặc nhập key.',
      ));
      return;
    }
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.exportToServer(secretKey: key);
    if (result.success) {
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: 'Đã upload backup lên cloud!',
      ));
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: result.error,
      ));
    }
  }

  Future<void> importFromFile() async {
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.importFromFilePicker();
    _handleImportResult(result);
  }

  Future<void> importFromServer({String? backupKey, String? secretKey}) async {
    final key = backupKey ?? secretKey ?? state.backupKey ?? await _repo.getBackupKey();
    if (key == null || key.trim().isEmpty) {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: 'Không lấy được backup key. Vui lòng đăng nhập.',
      ));
      return;
    }
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.importFromServer(secretKey: key.trim());
    _handleImportResult(result);
  }

  void _handleImportResult(ImportResult result) {
    if (result.success) {
      final s = result.summary;
      if (s == null) {
        emit(state.copyWith(
          status: BackupStatus.success,
          successMessage: 'Import thành công!',
        ));
        return;
      }
      final msg = 'Import thành công!\n'
          '• User: ${s.usersUpdated} bản ghi được thêm/cập nhật\n'
          '• ${s.vocabulariesAdded} từ vựng · ${s.tagsAdded} tag · ${s.vocabularyTagsAdded} gắn tag\n'
          '• ${s.unitsAdded} unit · ${s.activitiesAdded} hoạt động\n'
          '• ${s.wordProgressMerged} tiến độ word · ${s.userItemsMerged} items';
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: msg,
        importSummary: s,
      ));
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: result.error ?? 'Lỗi không xác định',
      ));
    }
  }
}
