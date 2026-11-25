import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';

enum ChoiceTileState { idle, correct, wrong, eliminated }

/// One answer of a multiple-choice question, styled like the feed's quiz
/// options: cyan when right, magenta when wrong.
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
          AppColors.xoayCyan,
          AppColors.xoayCyan.withValues(alpha: 0.14),
          AppColors.xoayCyan,
          Icons.check_circle_rounded,
        ),
      ChoiceTileState.wrong => (
          AppColors.xoayMagenta,
          AppColors.xoayMagenta.withValues(alpha: 0.14),
          AppColors.xoayMagenta,
          Icons.cancel_rounded,
        ),
      ChoiceTileState.eliminated => (
          AppColors.xoayLine,
          AppColors.xoaySurface.withValues(alpha: 0.25),
          AppColors.xoayPaper.withValues(alpha: 0.35),
          null,
        ),
      ChoiceTileState.idle => (
          AppColors.xoayGlassBorder,
          AppColors.xoaySurface2.withValues(alpha: 0.7),
          AppColors.xoayPaper,
          null,
        ),
    };
    final labelFg = state == ChoiceTileState.idle ? AppColors.xoayGold : fg;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: border,
            width: state == ChoiceTileState.idle ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelFg.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: labelFg.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: labelFg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: fg,
                  decoration: state == ChoiceTileState.eliminated
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: fg,
                ),
              ),
            ),
            if (icon != null) Icon(icon, size: 22, color: fg),
          ],
        ),
      ),
    );
  }
}
