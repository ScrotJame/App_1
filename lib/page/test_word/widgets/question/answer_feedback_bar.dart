import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../../../../generated/l10n.dart';
import '../../logic/test_answer.dart';
import '../../logic/test_kind_question.dart';
import '../ui_test_components.dart';

/// Shown once a question is answered: right or wrong, the answer, "next".
class AnswerFeedbackBar extends StatelessWidget {
  const AnswerFeedbackBar({
    super.key,
    required this.question,
    required this.answer,
    required this.isCorrect,
    required this.isLast,
    required this.loading,
    required this.onNext,
  });

  final TestQuestion question;
  final TestAnswer answer;
  final bool isCorrect;
  final bool isLast;
  final bool loading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final color = isCorrect ? AppColors.xoayCyan : AppColors.xoayMagenta;
    return TestScreenBottomBar(
      color: Color.alphaBlend(
        color.withValues(alpha: 0.16),
        AppColors.xoaySurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _title(s),
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ],
          ),
          for (final line in _details(s))
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 32),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.xoayPaper.withValues(alpha: 0.75),
                ),
              ),
            ),
          const SizedBox(height: 14),
          TestScreenPrimaryButton(
            label: isLast ? s.test_see_result : s.test_next,
            icon: Icons.arrow_forward_rounded,
            loading: loading,
            height: 50,
            onTap: onNext,
          ),
        ],
      ),
    );
  }

  String _title(S s) {
    if (isCorrect) return s.test_correct;
    if (answer is TimedOut) return s.test_time_up;
    return s.test_answer_is(_correctText(s));
  }

  String _correctText(S s) => switch (question) {
        final MultipleChoiceQuestion q => q.correctChoice,
        final TrueFalseQuestion q => q.isMatch ? s.test_true : s.test_false,
        final TypingQuestion q => q.accepted.join(' / '),
      };

  List<String> _details(S s) {
    final q = question;
    final current = answer;
    final word = q.entry.word;
    final reading = q.entry.pronunciation ?? '';
    return [
      if (!isCorrect && current is TimedOut) s.test_answer_is(_correctText(s)),
      if (!isCorrect && q is TrueFalseQuestion)
        s.test_true_false_answer(word, q.entry.meaning),
      if (q is ListeningQuestion) reading.isEmpty ? word : '$word · $reading',
      if (!isCorrect &&
          q is TypingQuestion &&
          current is TextAnswer &&
          current.text.trim().isNotEmpty)
        s.test_your_answer(current.text.trim()),
    ];
  }
}
