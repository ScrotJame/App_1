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
                color: AppColors.kAmberBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.kAmberBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: AppColors.kAmberText),
                  const SizedBox(width: 6),
                  Text(
                    S.of(context).test_hint,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.kAmberText,
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
                      color: AppColors.kBlue, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '$remaining',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
