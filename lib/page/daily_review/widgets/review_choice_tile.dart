import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';

enum ReviewChoiceState { idle, correct, wrong }

class ReviewChoiceTile extends StatelessWidget {
  const ReviewChoiceTile({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
  });

  final String label;
  final String text;
  final ReviewChoiceState state;
  final VoidCallback? onTap;

  Color get _accent => switch (state) {
        ReviewChoiceState.idle => AppColors.kBlue,
        ReviewChoiceState.correct => AppColors.kGreen,
        ReviewChoiceState.wrong => AppColors.kRed,
      };

  IconData get _icon => switch (state) {
        ReviewChoiceState.idle => Icons.radio_button_unchecked_rounded,
        ReviewChoiceState.correct => Icons.check_circle_rounded,
        ReviewChoiceState.wrong => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final idle = state == ReviewChoiceState.idle;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: idle ? AppColors.white : _accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: idle ? AppColors.kBorder : _accent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: idle ? AppColors.kBlueBg : _accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: idle ? AppColors.textBlack : _accent,
                ),
              ),
            ),
            Icon(_icon,
                color: idle ? AppColors.kBorder : _accent, size: 22),
          ],
        ),
      ),
    );
  }
}
