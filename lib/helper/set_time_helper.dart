import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/service/sm2/sm2_algorithm.dart';

/// Kết quả tính thời gian ôn tập tiếp theo.
///
/// - [nextReview]: Thời điểm ôn tập tiếp theo.
/// - [sm2Result]: Kết quả SM-2 (chỉ có giá trị khi level > 5).
class NextReviewResult {
  final DateTime nextReview;
  final SM2Result? sm2Result;

  const NextReviewResult({
    required this.nextReview,
    this.sm2Result,
  });
}

class SetTimeHelper {
  /// Tính thời gian ôn tập tiếp theo dựa trên [level] của từ vựng.
  ///
  /// - **level 0–4**: Khoảng lặp ngắn (phút/giờ), áp dụng logic bỏ qua giờ ngủ.
  /// - **level 5**: Khoảng lặp dài đầu tiên (8 ngày), không áp dụng sleep skip.
  /// - **level > 5**: Dùng thuật toán SM-2. Bắt buộc truyền đủ các tham số SM-2.
  ///
  /// Trả về [NextReviewResult] chứa [DateTime] và [SM2Result] (nếu dùng SM-2).
  static NextReviewResult calculateNextReviewTime(
    int level, {
    // SM-2 params — bắt buộc khi level > 5
    DifficultyRating? rating,
    int? prevRepetitions,
    int? prevInterval,
    double? prevEaseFactor,
  }) {
    if (level > 5) {
      assert(rating != null, 'rating is required when level > 5');
      assert(prevRepetitions != null, 'prevRepetitions is required when level > 5');
      assert(prevInterval != null, 'prevInterval is required when level > 5');
      assert(prevEaseFactor != null, 'prevEaseFactor is required when level > 5');

      final sm2Result = SM2Algorithm.calculate(
        rating: rating!,
        prevRepetitions: prevRepetitions!,
        prevInterval: prevInterval!,
        prevEaseFactor: prevEaseFactor!,
      );

      return NextReviewResult(
        nextReview: sm2Result.nextReview,
        sm2Result: sm2Result,
      );
    }

    final now = DateTime.now();
    Duration durationToWait;

    switch (level) {
      case 0:
        durationToWait = const Duration(minutes: 5);
        break;
      case 1:
        durationToWait = const Duration(minutes: 15);
        break;
      case 2:
        durationToWait = const Duration(minutes: 45);
        break;
      case 3:
        durationToWait = const Duration(hours: 1);
        break;
      case 4:
        durationToWait = const Duration(hours: 2);
        break;
      case 5:
      default:
        durationToWait = const Duration(days: 8);
        break;
    }

    final nextReview = level <= 4
        ? _addActiveDuration(now, durationToWait)
        : now.add(durationToWait);

    return NextReviewResult(nextReview: nextReview);
  }

  /// Cộng thêm [duration] vào [start], bỏ qua khoảng thời gian ngủ (00:00–06:00).
  static DateTime _addActiveDuration(DateTime start, Duration duration) {
    DateTime current = start;
    Duration remaining = duration;

    while (remaining.inMicroseconds > 0) {
      if (current.hour < 6) {
        current = DateTime(
            current.year, current.month, current.day, 6, 0, 0);
      } else {
        final nextMidnight = DateTime(
            current.year, current.month, current.day + 1, 0, 0, 0);
        final timeToMidnight = nextMidnight.difference(current);

        if (remaining <= timeToMidnight) {
          current = current.add(remaining);
          remaining = Duration.zero;
        } else {
          current = nextMidnight;
          remaining -= timeToMidnight;
        }
      }
    }
    return current;
  }
}