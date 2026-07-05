import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../commons/enums.dart';
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

  /// Gọi ngay sau khi đăng nhập thành công (email/Google/Apple) — ví dụ từ
  /// AuthCubit hoặc listener authStateChanges ở app.dart — để tự động tải
  /// bản backup mới nhất trên Firestore về máy mới. Người dùng không cần
  /// nhập secret key thủ công vì key giờ chính là uid của tài khoản.
  ///
  /// Chạy âm thầm: nếu tài khoản chưa từng backup (lần đầu dùng) hoặc mất
  /// mạng thì bỏ qua, không làm phiền người dùng bằng dialog lỗi ngay lúc
  /// họ vừa đăng nhập xong.
  Future<void> autoSyncFromServer() async {
    final key = await _repo.getBackupKey();
    if (key == null) return; // chưa đăng nhập, không có gì để đồng bộ

    emit(state.copyWith(status: BackupStatus.loading, backupKey: key));
    final result = await _repo.autoSyncFromServer();

    final isNoBackupYet =
        !result.success && (result.error?.contains('Không tìm thấy') ?? false);
    if (isNoBackupYet) {
      // Tài khoản mới toanh, chưa từng export lên server -> không phải lỗi
      emit(state.copyWith(status: BackupStatus.initial));
      return;
    }

    _handleImportResult(result, silent: true);
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

  Future<void> exportToServer() async {
    final key = await _repo.getBackupKey();
    if (key == null || key.isEmpty) {
      print('BackupCubit: exportToServer - Không lấy được backup key');
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

  Future<void> importFromServer() async {
    final key = await _repo.getBackupKey();
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

  void _handleImportResult(ImportResult result, {bool silent = false}) {
    if (result.success) {
      final s = result.summary;
      final msg = s == null
          ? 'Import thành công!'
          : 'Import thành công!\n'
          '• User: ${s.usersUpdated} bản ghi được thêm/cập nhật\n'
          '• ${s.vocabulariesAdded} từ vựng · ${s.tagsAdded} tag · ${s.vocabularyTagsAdded} gắn tag\n'
          '• ${s.unitsAdded} unit · ${s.activitiesAdded} hoạt động\n'
          '• ${s.wordProgressMerged} tiến độ word · ${s.userItemsMerged} items';
      emit(state.copyWith(
        status: BackupStatus.success,
        // Auto-sync ngầm sau khi đăng nhập thì không bật popup, tránh
        // làm phiền người dùng ngay lúc họ vừa vào app.
        successMessage: silent ? null : msg,
        importSummary: s,
      ));
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: silent ? null : (result.error ?? 'Lỗi không xác định'),
      ));
    }
  }
}
