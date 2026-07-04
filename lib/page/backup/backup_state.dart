part of 'backup_cubit.dart';

enum BackupMode { file, server }

enum BackupStatus { initial, loading, success, failed }

enum AuthStatus { unauthenticated, authenticated, loading }

const _absent = Object();

class BackupState extends Equatable {
  const BackupState({
    this.status = BackupStatus.initial,
    this.mode = BackupMode.file,
    this.authStatus = AuthStatus.loading,
    this.errorMessage,
    this.successMessage,
    this.exportedFilePath,
    this.importSummary,
    this.backupKey,
  });

  final BackupStatus status;
  final BackupMode mode;
  final AuthStatus authStatus;
  final String? errorMessage;
  final String? successMessage;
  final String? exportedFilePath;
  final ImportSummary? importSummary;
  final String? backupKey;

  bool get isLoading => status == BackupStatus.loading;
  bool get isAuthenticated => authStatus == AuthStatus.authenticated;

  BackupState copyWith({
    BackupStatus? status,
    BackupMode? mode,
    AuthStatus? authStatus,
    Object? errorMessage = _absent,
    Object? successMessage = _absent,
    Object? exportedFilePath = _absent,
    Object? importSummary = _absent,
    Object? backupKey = _absent,
  }) {
    return BackupState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      authStatus: authStatus ?? this.authStatus,
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
    authStatus,
    errorMessage,
    successMessage,
    exportedFilePath,
    importSummary,
    backupKey,
  ];
}