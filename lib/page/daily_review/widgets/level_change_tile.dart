import 'package:flutter/material.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../daily_review_cubit.dart';

class LevelChangeTile extends StatelessWidget {
  const LevelChangeTile({super.key, required this.change, this.dark = false});

  final DailyReviewWordChange change;

  /// Drawn for the dark feed gradient (the Test result screen).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = switch ((change.isUp, dark)) {
      (true, false) => AppColors.kGreen,
      (false, false) => AppColors.kRed,
      (true, true) => AppColors.xoayCyan,
      (false, true) => AppColors.xoayMagenta,
    };
    final textColor = dark ? AppColors.xoayPaper : AppColors.textBlack;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? AppColors.xoayGlass : AppColors.white,
        borderRadius: BorderRadius.circular(dark ? 16 : 12),
        border: Border.all(
          color: dark ? AppColors.xoayGlassBorder : AppColors.kBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.word,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  change.meaning,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: dark ? 0.6 : 0.55),
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
