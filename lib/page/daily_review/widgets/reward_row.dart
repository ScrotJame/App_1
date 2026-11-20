import 'package:flutter/material.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';

class RewardRow extends StatelessWidget {
  const RewardRow({
    super.key,
    required this.label,
    required this.xp,
    required this.gems,
  });

  final String label;
  final int xp;
  final int gems;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textBlack),
            ),
          ),
          Text(
            S.of(context).daily_review_reward_value(xp, gems),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.kBlue,
            ),
          ),
        ],
      ),
    );
  }
}
