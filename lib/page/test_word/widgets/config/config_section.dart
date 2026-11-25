import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../ui_test_components.dart';

/// A titled block of the config screen, on a glass card.
class ConfigSection extends StatelessWidget {
  const ConfigSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.xoayCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.xoayPaper,
                  ),
                ),
              ),
              if (trailing case final widget?) widget,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
