import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';

class RailButton extends StatelessWidget {
  const RailButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor.withOpacity(0.22)
                  : Colors.white.withOpacity(0.08),
            ),
            child: Icon(icon, color: AppColors.xoayPaper, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.xoayPaper.withOpacity(0.58),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}