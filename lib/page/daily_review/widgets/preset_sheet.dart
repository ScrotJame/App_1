import 'package:flutter/material.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../logic/daily_target.dart';

/// Lets the user pick 10 / 20 / 30. Returns the choice, or null.
Future<int?> showDailyReviewPresetSheet(
  BuildContext context, {
  required int current,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final s = S.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.daily_review_words_per_day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.daily_review_preset_applies_tomorrow,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textBlack.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              for (final preset in DailyTarget.presets)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.daily_review_preset_option(preset)),
                  trailing: preset == current
                      ? const Icon(Icons.check_rounded, color: AppColors.kBlue)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(preset),
                ),
            ],
          ),
        ),
      );
    },
  );
}
