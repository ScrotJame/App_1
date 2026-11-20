import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../data/daily_review_status.dart';

/// HUD badge: icon only before the review exists, `done/total` while it is
/// open, a check mark once it is finished.
class DailyReviewBadge extends StatelessWidget {
  const DailyReviewBadge({super.key, required this.status, required this.onTap});

  final DailyReviewStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = status.progress == DailyReviewProgress.completed;
    final inProgress = status.progress == DailyReviewProgress.inProgress;
    final color = completed ? AppColors.kGreen : AppColors.gachaNeonCyan;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.textBlack.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.fact_check_rounded,
              color: color,
              size: 16,
            ),
            if (inProgress) ...[
              const SizedBox(width: 3),
              Text(
                '${status.answered}/${status.total}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
