part of 'backup_cubit.dart';

enum BackupMode { file, server }

enum BackupStatus { initial, loading, success, failed }

// Sentinel: dùng để phân biệt "không truyền vào" vs "truyền null vào"
const _absent = Object();

class BackupState extends Equatable {
  const BackupState({
    this.status = BackupStatus.initial,
    this.mode = BackupMode.file,
    this.errorMessage,
    this.successMessage,
    this.exportedFilePath,
    this.importSummary,
  });

  final BackupStatus status;

  /// Chế độ hiện tại: file local hoặc server (secret key)
  final BackupMode mode;

  /// Chỉ có giá trị khi status == failed
  final String? errorMessage;

  /// Chỉ có giá trị khi status == success
  final String? successMessage;

  /// Đường dẫn file vừa export (chỉ có khi exportToFile thành công)
  final String? exportedFilePath;

  /// Kết quả import chi tiết
  final ImportSummary? importSummary;

  bool get isLoading => status == BackupStatus.loading;

  /// Dùng sentinel [_absent] để phân biệt "không truyền" vs "truyền null".
  /// Các field dạng message (errorMessage, successMessage) reset về null
  /// mỗi lần gọi copyWith — đây là hành vi đúng vì chúng chỉ sống 1 lần.
  /// Các field "dữ liệu" (exportedFilePath, importSummary) giữ nguyên
  /// nếu không truyền vào.
  BackupState copyWith({
    BackupStatus? status,
    BackupMode? mode,
    // Dùng Object? + sentinel thay vì String? để phân biệt absent vs null
    Object? errorMessage = _absent,
    Object? successMessage = _absent,
    Object? exportedFilePath = _absent,
    Object? importSummary = _absent,
  }) {
    return BackupState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      // Message fields: reset về null khi không truyền (clear sau mỗi action)
      errorMessage: errorMessage == _absent
          ? null
          : errorMessage as String?,
      successMessage: successMessage == _absent
          ? null
          : successMessage as String?,
      // Data fields: giữ nguyên khi không truyền, nhận null nếu truyền null
      exportedFilePath: exportedFilePath == _absent
          ? this.exportedFilePath
          : exportedFilePath as String?,
      importSummary: importSummary == _absent
          ? this.importSummary
          : importSummary as ImportSummary?,
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
  ];
}