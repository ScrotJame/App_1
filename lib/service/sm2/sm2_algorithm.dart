import 'package:test_abc/commons/enums.dart';

class SM2Result {
  final int repetitions;
  final int interval; // in days
  final double easeFactor;
  final DateTime nextReview;

  SM2Result({
    required this.repetitions,
    required this.interval,
    required this.easeFactor,
    required this.nextReview,
  });
}

class SM2Algorithm {
  /// Calculate SM-2 spaced repetition values.
  ///
  /// - [rating] The user's difficulty selection (again, hard, good, easy)
  /// - [prevRepetitions] The current consecutive correct recall streak
  /// - [prevInterval] The current repetition interval in days
  /// - [prevEaseFactor] The ease rating (starts at 2.5)
  static SM2Result calculate({
    required DifficultyRating rating,
    required int prevRepetitions,
    required int prevInterval,
    required double prevEaseFactor,
  }) {
    // Map DifficultyRating to standard SM-2 quality (0 to 5)
    int q;
    switch (rating) {
      case DifficultyRating.again:
        q = 1; // Incorrect, forgot
        break;
      case DifficultyRating.hard:
        q = 3; // Correct, serious difficulty
        break;
      case DifficultyRating.good:
        q = 4; // Correct, normal difficulty
        break;
      case DifficultyRating.easy:
        q = 5; // Correct, easy response
        break;
    }

    int repetitions;
    int interval;
    double easeFactor;

    if (q < 3) {
      // Incorrect answer, reset repetitions, reset interval to 1 day
      repetitions = 0;
      interval = 1;
      easeFactor = prevEaseFactor; // retain ease factor, or reduce slightly
    } else {
      // Correct answer, update SM-2 properties
      if (prevRepetitions == 0) {
        repetitions = 1;
        interval = 1; // 1 day
      } else if (prevRepetitions == 1) {
        repetitions = 2;
        interval = 6; // 6 days
      } else {
        repetitions = prevRepetitions + 1;
        interval = (prevInterval * prevEaseFactor).round();
      }

      // Calculate ease factor adjustment
      easeFactor = prevEaseFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    }

    // Ease Factor must not fall below 1.3
    if (easeFactor < 1.3) {
      easeFactor = 1.3;
    }

    // Set next review time (rounded to clean dates/times)
    final now = DateTime.now();
    final nextReview = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: interval));

    return SM2Result(
      repetitions: repetitions,
      interval: interval,
      easeFactor: easeFactor,
      nextReview: nextReview,
    );
  }
}
