import 'package:flutter/cupertino.dart';

import '../../../commons/app_colors.dart';

class QuizOption extends StatelessWidget {
  const QuizOption({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.xoaySurface2;
    Color borderColor = AppColors.xoayLine;
    Color textColor = AppColors.xoayPaper;

    if (isAnswered && isCorrect) {
      bgColor = AppColors.xoayCyan.withOpacity(0.12);
      borderColor = AppColors.xoayCyan;
      textColor = AppColors.xoayCyan;
    } else if (isAnswered && isSelected) {
      bgColor = AppColors.xoayMagenta.withOpacity(0.12);
      borderColor = AppColors.xoayMagenta;
      textColor = AppColors.xoayMagenta;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
