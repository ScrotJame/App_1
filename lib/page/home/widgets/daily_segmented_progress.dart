import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';

class DailySegmentedProgress extends StatelessWidget {
  final int completed;
  final int target;
  final VoidCallback? onTap;

  const DailySegmentedProgress({
    super.key,
    required this.completed,
    this.target = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTarget = target <= 0 ? 10 : target;
    final totalSegments = effectiveTarget.clamp(3, 10);
    final ratio = (completed / effectiveTarget).clamp(0.0, 1.0);
    final activeSegments = (ratio * totalSegments).round();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gachaGlassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gachaGlassBorder, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 13,
                  color: AppColors.gachaNeonCyan,
                ),
                const SizedBox(width: 3),
                Text(
                  '$completed/$effectiveTarget từ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 75,
              child: Row(
                children: List.generate(totalSegments, (index) {
                  final isActive = index < activeSegments;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(
                        right: index < totalSegments - 1 ? 2.5 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.gachaNeonCyan
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.gachaNeonCyan
                                      .withValues(alpha: 0.8),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
