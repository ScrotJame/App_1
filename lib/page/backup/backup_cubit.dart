import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import '../../commons/enums.dart';
import '../../models/backup_entity.dart';
import '../../repository/backup_data_repository.dart';
import 'package:test_abc/generated/l10n.dart';

part 'backup_state.dart';

class BackupCubit extends Cubit<BackupState> {
  final BackupRepository _repo;

  /// Runs after a successful import, e.g. to rebuild the review reminder
  /// plan from the restored words. [silent] is true for the automatic sync
  /// at sign-in, which happens on app start and must not count as studying.
  final Future<void> Function(bool silent)? _onImported;

  BackupCubit(this._repo, {Future<void> Function(bool silent)? onImported})
      : _onImported = onImported,
        super(const BackupState());

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
        errorMessage: S.current.backup_key_missing_retry,
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

    await _handleImportResult(result, silent: true);
  }

  Future<void> exportAndShare() async {
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.exportAndShare();
    if (result.success) {
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: S.current.backup_export_success,
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
    if (result.cancelled) {
      emit(state.copyWith(status: BackupStatus.initial));
    } else if (result.success) {
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: S.current.backup_file_saved,
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
        errorMessage: S.current.backup_key_missing_login_or_enter,
      ));
      return;
    }
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.exportToServer(secretKey: key);
    if (result.success) {
      emit(state.copyWith(
        status: BackupStatus.success,
        successMessage: S.current.backup_upload_success,
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
    await _handleImportResult(result);
  }

  Future<void> importFromServer() async {
    final key = await _repo.getBackupKey();
    if (key == null || key.trim().isEmpty) {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: S.current.backup_key_missing_login,
      ));
      return;
    }
    emit(state.copyWith(status: BackupStatus.loading));
    final result = await _repo.importFromServer(secretKey: key.trim());
    await _handleImportResult(result);
  }

  Future<void> _handleImportResult(ImportResult result,
      {bool silent = false}) async {
    if (result.success) {
      final s = result.summary;
      final l10n = S.current;
      final msg = s == null
          ? l10n.import_success
          : [
              l10n.import_success,
              l10n.import_summary_users(s.usersUpdated),
              l10n.import_summary_vocabulary(
                  s.vocabulariesAdded, s.tagsAdded, s.vocabularyTagsAdded),
              l10n.import_summary_units(s.unitsAdded, s.activitiesAdded),
              l10n.import_summary_progress(
                  s.wordProgressMerged, s.userItemsMerged),
              l10n.import_summary_history(s.learningHistoryAdded,
                  s.achievementsMerged, s.companionsMerged),
            ].join('\n');
      emit(state.copyWith(
        status: BackupStatus.success,
        // Auto-sync ngầm sau khi đăng nhập thì không bật popup, tránh
        // làm phiền người dùng ngay lúc họ vừa vào app.
        successMessage: silent ? null : msg,
        importSummary: s,
      ));
      await _runOnImported(silent);
    } else {
      emit(state.copyWith(
        status: BackupStatus.failed,
        errorMessage: silent ? null : (result.error ?? S.current.unknown_error),
      ));
    }
  }

  /// The import already succeeded; a failure here must not turn it into an
  /// error for the user.
  Future<void> _runOnImported(bool silent) async {
    final onImported = _onImported;
    if (onImported == null) return;
    try {
      await onImported(silent);
    } catch (e) {
      debugPrint('BackupCubit: after-import step failed: $e');
    }
  }
}
