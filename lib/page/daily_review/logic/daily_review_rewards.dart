import 'package:equatable/equatable.dart';

import '../../test_word/test_cubit.dart' show TestState;
import '../data/daily_review_session.dart';

class DailyReviewRewardBreakdown extends Equatable {
  const DailyReviewRewardBreakdown({
    this.wordXp = 0,
    this.wordGems = 0,
    this.completionXp = 0,
    this.completionGems = 0,
    this.accuracyXp = 0,
    this.accuracyGems = 0,
  });

  static const none = DailyReviewRewardBreakdown();

  final int wordXp;
  final int wordGems;
  final int completionXp;
  final int completionGems;
  final int accuracyXp;
  final int accuracyGems;

  int get totalXp => wordXp + completionXp + accuracyXp;

  int get totalGems => wordGems + completionGems + accuracyGems;

  @override
  List<Object?> get props =>
      [wordXp, wordGems, completionXp, completionGems, accuracyXp, accuracyGems];
}

/// What a finished official run pays.
class DailyReviewRewards {
  DailyReviewRewards._();

  static const int completionXp = 30;
  static const int completionGems = 20;
  static const int accuracyXp = 20;
  static const int accuracyGems = 10;
  static const double accuracyThreshold = 0.8;

  static DailyReviewRewardBreakdown of(DailyReviewSession session) {
    if (!session.isCompleted) return DailyReviewRewardBreakdown.none;

    var wordXp = 0;
    var wordGems = 0;
    for (final id in session.wordIds) {
      final step = session.levels[id];
      if (step == null || !step.isUp) continue;
      wordXp += TestState.xpForLevel(step.after);
      wordGems += TestState.gemsForLevel(step.after);
    }

    final accurate =
        session.answeredCount > 0 && session.accuracy >= accuracyThreshold;
    return DailyReviewRewardBreakdown(
      wordXp: wordXp,
      wordGems: wordGems,
      completionXp: completionXp,
      completionGems: completionGems,
      accuracyXp: accurate ? accuracyXp : 0,
      accuracyGems: accurate ? accuracyGems : 0,
    );
  }
}
