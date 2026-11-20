import 'package:equatable/equatable.dart';

import 'daily_review_session.dart';

enum DailyReviewProgress { notCreated, inProgress, completed }

/// What the HUD badge and the Test banner show about today's review.
class DailyReviewStatus extends Equatable {
  const DailyReviewStatus({
    required this.progress,
    this.answered = 0,
    this.total = 0,
  });

  static const notCreated =
      DailyReviewStatus(progress: DailyReviewProgress.notCreated);

  factory DailyReviewStatus.of(DailyReviewSession? session) {
    if (session == null) return notCreated;
    return DailyReviewStatus(
      progress: session.isCompleted
          ? DailyReviewProgress.completed
          : DailyReviewProgress.inProgress,
      answered: session.answeredCount,
      total: session.total,
    );
  }

  final DailyReviewProgress progress;
  final int answered;
  final int total;

  @override
  List<Object?> get props => [progress, answered, total];
}
