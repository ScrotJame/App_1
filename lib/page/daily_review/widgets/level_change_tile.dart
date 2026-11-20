import 'package:flutter/material.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../daily_review_cubit.dart';

class LevelChangeTile extends StatelessWidget {
  const LevelChangeTile({super.key, required this.change});

  final DailyReviewWordChange change;

  @override
  Widget build(BuildContext context) {
    final color = change.isUp ? AppColors.kGreen : AppColors.kRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.word,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBlack,
                  ),
                ),
                Text(
                  change.meaning,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textBlack.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            S.of(context).daily_review_level_step(change.before, change.after),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Icon(
            change.isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}
