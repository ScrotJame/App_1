import 'package:flutter/material.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../logic/daily_review_question.dart';

class ReviewWordCard extends StatelessWidget {
  const ReviewWordCard({super.key, required this.question});

  final DailyReviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.kBlueBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            (question.asksMeaning ? s.fieldVocabulary : s.fieldMeaning)
                .toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.kBlue,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
          ),
          if (question.pronunciation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              question.pronunciation,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textBlack.withValues(alpha: 0.5),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            question.asksMeaning
                ? s.test_question_word_to_meaning
                : s.test_question_meaning_to_word,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textBlack.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
