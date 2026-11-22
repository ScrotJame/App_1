import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';

class TimerBadge extends StatelessWidget {
  const TimerBadge({
    super.key,
    required this.text,
    required this.warning,
    required this.critical,
  });

  final String text;
  final bool warning;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final fg = critical
        ? AppColors.kRed
        : warning
            ? AppColors.kAmber
            : AppColors.kBlue;
    final bg = critical || warning
        ? fg.withValues(alpha: 0.12)
        : AppColors.kBlueBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
