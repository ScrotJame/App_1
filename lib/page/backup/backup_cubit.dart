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

  // ─── EXPORT ───────────────────────────────────────────────────────────────

  /// Xuất file JSON + mở share sheet
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

  /// Lưu file JSON vào bộ nhớ máy (Downloads / Documents)
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

  /// Upload backup lên server bằng secret key
  Future<void> exportToServer(String secretKey) async {
    if (secretKey.trim().isEmpty) {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: 'Vui lòng nhập secret key',
      ));
      return;
    }
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.exportToServer(secretKey: secretKey.trim());
    if (result.success) {
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: 'Đã upload backup lên server!',
      ));
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: result.error,
      ));
    }
  }

  // ─── IMPORT ───────────────────────────────────────────────────────────────

  /// Mở file picker → chọn file .json → import
  Future<void> importFromFile() async {
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.importFromFilePicker();
    _handleImportResult(result);
  }

  /// Tải backup từ server bằng secret key → import
  Future<void> importFromServer(String secretKey) async {
    if (secretKey.trim().isEmpty) {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: 'Vui lòng nhập secret key',
      ));
      return;
    }
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.importFromServer(secretKey: secretKey.trim());
    _handleImportResult(result);
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  void _handleImportResult(ImportResult result) {
    if (result.success) {
      final s = result.summary;
      if (s == null) {
        // Phòng trường hợp summary không có (không nên xảy ra nhưng an toàn hơn)
        emit(state.copyWith(
          status: BackupStatus.success,
          successMessage: 'Import thành công!',
        ));
        return;
      }
      final msg = 'Import thành công!\n'
          '• ${s.vocabulariesAdded} từ vựng · ${s.tagsAdded} tag\n'
          '• ${s.unitsAdded} unit · ${s.activitiesAdded} hoạt động\n'
          '• ${s.wordProgressMerged} tiến độ được cập nhật';
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