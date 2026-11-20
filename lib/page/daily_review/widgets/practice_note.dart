import 'package:flutter/material.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';

class PracticeNote extends StatelessWidget {
  const PracticeNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.kAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.replay_rounded, color: AppColors.kAmber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.of(context).daily_review_practice_note,
              style: const TextStyle(
                color: AppColors.kAmber,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
