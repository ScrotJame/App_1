import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';

class ConfigChip extends StatelessWidget {
  const ConfigChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.xoayGold : AppColors.xoayGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.xoayGold : AppColors.xoayGlassBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.xoayGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.xoayInk : AppColors.xoayPaper,
          ),
        ),
      ),
    );
  }
}
