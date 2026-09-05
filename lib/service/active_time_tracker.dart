/// Quản lý việc theo dõi thời gian hoạt động thực tế của người dùng.
///
/// Tránh tình trạng người dùng mở app rồi để đấy mà vẫn tính thời gian:
/// - Mặc định sau [idleThreshold] (30 giây) không có thao tác (chạm/cuộn/nhập),
///   trạng thái được tính là `idle` và không cộng dồn thời gian active.
/// - Khi người dùng có thao tác chạm/gõ trở lại (`recordActivity`), trạng thái
///   chuyển lại `active` và tiếp tục đếm.
class ActiveTimeTracker {
  final Duration idleThreshold;
  DateTime _lastActivityTime;
  int _activeSeconds;

  ActiveTimeTracker({
    this.idleThreshold = const Duration(seconds: 30),
    DateTime? initialTime,
    int initialActiveSeconds = 0,
  })  : _lastActivityTime = initialTime ?? DateTime.now(),
        _activeSeconds = initialActiveSeconds;

  int get activeSeconds => _activeSeconds;
  DateTime get lastActivityTime => _lastActivityTime;

  /// Kiểm tra xem hiện tại người dùng có đang 'để app đấy' (idle) hay không.
  bool isIdle(DateTime now) {
    return now.difference(_lastActivityTime) > idleThreshold;
  }

  /// Ghi nhận thao tác tương tác của người dùng.
  void recordActivity(DateTime now) {
    _lastActivityTime = now;
  }

  /// Gọi định kỳ (tick): nếu đang active thì cộng thêm thời gian bước nhảy.
  void tick(DateTime now, {Duration step = const Duration(seconds: 1)}) {
    if (!isIdle(now)) {
      _activeSeconds += step.inSeconds;
    }
  }

  /// Cập nhật thủ công số giây đã tích lũy (khi nạp từ storage).
  void setActiveSeconds(int seconds) {
    _activeSeconds = seconds;
  }
}
