import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../ui_test_components.dart';

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
    final color = critical
        ? AppColors.xoayMagenta
        : warning
            ? AppColors.xoayGoldDeep
            : AppColors.xoayPaper;
    return TestScreenPill(icon: Icons.timer_rounded, text: text, color: color);
  }
}
