// file: lib/helper/review_time_helper.dart

class SetTimeHelper {
  static DateTime calculateNextReviewTime(int level) {
    final now = DateTime.now();
    Duration durationToWait;

    switch (level) {
      case 1:
        durationToWait = const Duration(hours: 2); //seconds
        break;
      case 2:
        durationToWait = const Duration(hours: 4);
        break;
      case 3:
        durationToWait = const Duration(hours: 6);
        break;
      case 4:
        durationToWait = const Duration(hours: 8);
        break;
      case 5:
      default:
        durationToWait = const Duration(days: 5);
        break;
    }

    return _addActiveDuration(now, durationToWait);
  }

  /// Hàm phụ trợ xử lý bỏ qua khung giờ ngủ (00:00 - 06:00)
  static DateTime _addActiveDuration(DateTime start, Duration duration) {
    DateTime current = start;
    Duration remaining = duration;

    while (remaining.inMicroseconds > 0) {
      if (current.hour >= 0 && current.hour < 6) {
        // Đóng băng lúc nửa đêm, nhảy cóc sang 6h sáng
        current = DateTime(current.year, current.month, current.day, 6, 0, 0);
      } else {
        // Tính khoảng thời gian từ hiện tại đến nửa đêm của ngày hôm sau
        DateTime nextMidnight = DateTime(current.year, current.month, current.day + 1, 0, 0, 0);
        Duration timeToMidnight = nextMidnight.difference(current);

        if (remaining <= timeToMidnight) {
          // Cộng nốt khoảng thời gian còn lại
          current = current.add(remaining);
          remaining = Duration.zero;
        } else {
          // Trừ đi thời gian trong ngày nay, tiếp tục vòng lặp qua ngày mai
          current = nextMidnight;
          remaining -= timeToMidnight;
        }
      }
    }
    return current;
  }
}