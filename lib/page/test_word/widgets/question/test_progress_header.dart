import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../../../../commons/enums.dart';
import '../../../../generated/l10n.dart';
import '../../test_kind_text.dart';
import '../ui_test_components.dart';

/// Progress bar, score and the kind of the current question.
class TestProgressHeader extends StatelessWidget {
  const TestProgressHeader({
    super.key,
    required this.progress,
    required this.score,
    required this.kind,
  });

  final double progress;
  final int score;
  final TestKind? kind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (kind case final k?)
                TestScreenPill(icon: k.icon, text: k.title, color: AppColors.xoayCyan)
              else
                const SizedBox(),
              TestScreenPill(
                icon: Icons.star_rounded,
                text: S.of(context).test_score_points(score),
                color: AppColors.xoayGold,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBar(),
        ],
      ),
    );
  }

  /// Gold-to-magenta bar, like the primary buttons.
  Widget _buildBar() {
    final value = progress.clamp(0.0, 1.0);
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.xoayLine,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        widthFactor: value,
        heightFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [AppColors.xoayGold, AppColors.xoayMagenta],
            ),
          ),
        ),
      ),
    );
  }
}
