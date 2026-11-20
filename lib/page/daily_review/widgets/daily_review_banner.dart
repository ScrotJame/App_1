import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../../../router/router.dart';
import '../data/daily_review_status.dart';
import 'daily_review_status_builder.dart';

/// "Today's review" banner at the top of the Test config screen.
class DailyReviewBanner extends StatelessWidget {
  const DailyReviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return DailyReviewStatusBuilder(
      builder: (context, status) {
        final s = S.of(context);
        final completed = status.progress == DailyReviewProgress.completed;
        final subtitle = switch (status.progress) {
          DailyReviewProgress.notCreated => s.daily_review_banner_new,
          DailyReviewProgress.inProgress =>
            s.daily_review_banner_progress(status.answered, status.total),
          DailyReviewProgress.completed => s.daily_review_banner_done,
        };
        return GestureDetector(
          onTap: () => context.push(Routes.dailyReview),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: completed ? AppColors.kGreen : AppColors.kBlue,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.fact_check_rounded,
                  color: completed ? AppColors.kGreen : AppColors.kBlue,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.daily_review_title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textBlack.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.kBlue),
              ],
            ),
          ),
        );
      },
    );
  }
}
