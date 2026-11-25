import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../../../router/router.dart';
import '../data/daily_review_status.dart';
import 'daily_review_status_builder.dart';

/// "Today's review" banner at the top of the Test config screen, drawn for
/// the dark feed gradient.
class DailyReviewBanner extends StatelessWidget {
  const DailyReviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return DailyReviewStatusBuilder(
      builder: (context, status) {
        final s = S.of(context);
        final completed = status.progress == DailyReviewProgress.completed;
        final accent = completed ? AppColors.xoayCyan : AppColors.xoayGold;
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
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : Icons.fact_check_rounded,
                    color: accent,
                    size: 24,
                  ),
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
                          fontWeight: FontWeight.w800,
                          color: AppColors.xoayPaper,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.xoayPaperDim,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent),
              ],
            ),
          ),
        );
      },
    );
  }
}
