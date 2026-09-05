import 'package:flutter/material.dart';
import '../../../commons/app_colors.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow({
    super.key,
    required this.label,
    this.dotColor = AppColors.xoayCyan,
  });

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.xoayPaper.withValues(alpha: 0.58),
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}
