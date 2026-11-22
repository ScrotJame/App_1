import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';

/// A titled block of the config screen.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.kBlue),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            if (trailing case final widget?) widget,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
