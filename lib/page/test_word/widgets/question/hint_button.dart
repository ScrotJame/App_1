import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../../../../generated/l10n.dart';

class HintButton extends StatelessWidget {
  const HintButton({
    super.key,
    required this.remaining,
    required this.enabled,
    required this.onTap,
  });

  final int remaining;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.xoayGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.xoayGold.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      size: 18, color: AppColors.xoayGold),
                  const SizedBox(width: 6),
                  Text(
                    S.of(context).test_hint,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.xoayGold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (remaining > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: const BoxDecoration(
                      color: AppColors.xoayMagenta, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '$remaining',
                    style: const TextStyle(
                      color: AppColors.xoayPaper,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
