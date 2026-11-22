import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';

enum ChoiceTileState { idle, correct, wrong, eliminated }

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
  });

  final String label;
  final String text;
  final ChoiceTileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color bg, Color fg, IconData? icon) = switch (state) {
      ChoiceTileState.correct => (
          AppColors.kGreen,
          AppColors.kGreenBg,
          AppColors.kGreen,
          Icons.check_circle_rounded,
        ),
      ChoiceTileState.wrong => (
          AppColors.kRed,
          AppColors.kRedBg,
          AppColors.kRed,
          Icons.cancel_rounded,
        ),
      ChoiceTileState.eliminated => (
          AppColors.kBorder,
          AppColors.kDisabledBg,
          AppColors.kTextMuted,
          null,
        ),
      ChoiceTileState.idle => (
          AppColors.kBorder,
          AppColors.white,
          AppColors.textBlack,
          Icons.radio_button_unchecked_rounded,
        ),
    };
    final labelFg = state == ChoiceTileState.idle ? AppColors.kBlue : fg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelFg.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: labelFg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fg,
                  decoration: state == ChoiceTileState.eliminated
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            if (icon != null)
              Icon(
                icon,
                size: 22,
                color: state == ChoiceTileState.idle
                    ? AppColors.kTextMuted
                    : fg,
              ),
          ],
        ),
      ),
    );
  }
}
