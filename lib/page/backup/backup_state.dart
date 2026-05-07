part of 'backup_cubit.dart';

enum BackupMode { file, server }

enum BackupStatus { initial, loading, success, failed }

const _absent = Object();

class BackupState extends Equatable {
  const BackupState({
    this.status = BackupStatus.initial,
    this.mode = BackupMode.file,
    this.errorMessage,
    this.successMessage,
    this.exportedFilePath,
    this.importSummary,
    this.backupKey,
  });

  final BackupStatus status;
  final BackupMode mode;
  final String? errorMessage;
  final String? successMessage;
  final String? exportedFilePath;
  final ImportSummary? importSummary;
  final String? backupKey;  // ← thêm

  bool get isLoading => status == BackupStatus.loading;

  BackupState copyWith({
    BackupStatus? status,
    BackupMode? mode,
    Object? errorMessage = _absent,
    Object? successMessage = _absent,
    Object? exportedFilePath = _absent,
    Object? importSummary = _absent,
    Object? backupKey = _absent,
  }) {
    return BackupState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      errorMessage: errorMessage == _absent ? null : errorMessage as String?,
      successMessage: successMessage == _absent ? null : successMessage as String?,
      exportedFilePath: exportedFilePath == _absent
          ? this.exportedFilePath
          : exportedFilePath as String?,
      importSummary: importSummary == _absent
          ? this.importSummary
          : importSummary as ImportSummary?,
      backupKey: backupKey == _absent
          ? this.backupKey
          : backupKey as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    mode,
    errorMessage,
    successMessage,
    exportedFilePath,
    importSummary,
    backupKey,
  ];
}