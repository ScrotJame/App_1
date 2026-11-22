import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../../../../commons/enums.dart';
import '../../../../generated/l10n.dart';
import '../../test_kind_text.dart';

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
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (kind case final k?) _buildKindChip(k) else const SizedBox(),
              _buildScore(context),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.kBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.kBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKindChip(TestKind kind) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.kBlueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 13, color: AppColors.kBlue),
          const SizedBox(width: 4),
          Text(
            kind.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.kBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScore(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.kAmberBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kAmberBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.kAmber),
          const SizedBox(width: 4),
          Text(
            S.of(context).test_score_points(score),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.kAmberText,
            ),
          ),
        ],
      ),
    );
  }
}
