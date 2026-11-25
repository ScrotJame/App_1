import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../../../../commons/enums.dart';
import '../../../../generated/l10n.dart';
import '../../test_kind_text.dart';

/// A kind of question that can be ticked on or off.
class TestKindCard extends StatelessWidget {
  const TestKindCard({
    super.key,
    required this.kind,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
    this.footer,
  });

  final TestKind kind;
  final bool selected;
  final VoidCallback onTap;

  /// Shown faded, e.g. listening without a voice. Still tappable.
  final bool dimmed;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.xoayGold : AppColors.xoayPaperDim;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.xoayGold.withValues(alpha: 0.14)
                : AppColors.xoaySurface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.xoayGold : AppColors.xoayGlassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(kind.icon, size: 22, color: color),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                kind.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.xoayGold : AppColors.xoayPaper,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dimmed
                    ? S.of(context).test_no_voice_for_scope
                    : kind.description,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.xoayPaperDim, height: 1.3),
              ),
              if (footer case final widget?) ...[
                const SizedBox(height: 6),
                widget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
