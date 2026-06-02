class ErrorUtils {
  /// Dịch các loại lỗi hệ thống và ngoại lệ thành thông điệp thân thiện với người dùng.
  static String networkErrorToMessage(dynamic error) {
    if (error == null) {
      return 'Đã xảy ra lỗi không xác định.';
    }

    final errorStr = error.toString().toLowerCase();

    // Lỗi liên quan đến cơ sở dữ liệu SQLite / Drift
    if (errorStr.contains('sqlite') || errorStr.contains('database') || errorStr.contains('drift')) {
      if (errorStr.contains('unique constraint')) {
        return 'Dữ liệu này đã tồn tại trong hệ thống.';
      }
      if (errorStr.contains('foreign key constraint')) {
        return 'Thao tác không hợp lệ do liên kết dữ liệu không tồn tại.';
      }
      return 'Lỗi lưu trữ dữ liệu. Vui lòng thử lại.';
    }

    // Lỗi Null Safety
    if (errorStr.contains('null check operator') || errorStr.contains('null value')) {
      return 'Không thể hoàn tất thao tác do dữ liệu bị thiếu hoặc không hợp lệ.';
    }

    // Lỗi mạng hoặc máy chủ (Firebase)
    if (errorStr.contains('network') || errorStr.contains('socketexception') || errorStr.contains('connection')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra lại thiết bị.';
    }
    if (errorStr.contains('firebase') || errorStr.contains('auth')) {
      return 'Lỗi xác thực hệ thống tài khoản. Vui lòng đăng nhập lại.';
    }

    // Lỗi mặc định khác
    return 'Lỗi: ${error.toString()}';
  }
}
