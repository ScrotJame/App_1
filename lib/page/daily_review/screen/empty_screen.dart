import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../../../router/router.dart';
import '../../test_word/widgets/button_widget.dart';

class DailyReviewEmptyScreen extends StatelessWidget {
  const DailyReviewEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded,
                color: AppColors.kBlue, size: 56),
            const SizedBox(height: 16),
            Text(
              s.daily_review_empty_title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.daily_review_empty_message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textBlack.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            buildPrimaryButton(
              label: s.daily_review_add_word,
              icon: Icons.add_rounded,
              onTap: () => context.push(Routes.addWord),
            ),
          ],
        ),
      ),
    );
  }
}
