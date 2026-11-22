import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../../../../generated/l10n.dart';
import '../../logic/test_answer.dart';
import '../../logic/test_kind_question.dart';
import 'swipe_answer_area.dart';

class TrueFalseQuestionView extends StatelessWidget {
  const TrueFalseQuestionView({
    super.key,
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final TrueFalseQuestion question;
  final TestAnswer? answer;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final reading = question.entry.pronunciation ?? '';
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.kBlueBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            question.entry.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
          ),
          if (reading.isNotEmpty)
            Text(reading,
                style:
                    const TextStyle(fontSize: 15, color: AppColors.kTextMuted)),
          const SizedBox(height: 10),
          const Icon(Icons.swap_vert_rounded, color: AppColors.kBlue, size: 22),
          const SizedBox(height: 10),
          Text(
            question.shownMeaning,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textBlack,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwipeAnswerArea(
          enabled: answer == null,
          onSwipe: onAnswer,
          child: card,
        ),
        const SizedBox(height: 10),
        Text(
          S.of(context).test_true_false_prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.kTextMuted,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildButton(context, value: true)),
            const SizedBox(width: 12),
            Expanded(child: _buildButton(context, value: false)),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, {required bool value}) {
    final current = answer;
    final answered = current != null;
    final picked = current is BoolAnswer ? current.value : null;
    final isRight = value == question.isMatch;
    final color = value ? AppColors.kGreen : AppColors.kRed;
    final filled = answered && isRight;
    final fg = filled ? AppColors.white : color;
    return Opacity(
      opacity: answered && !isRight ? 0.4 : 1,
      child: GestureDetector(
        onTap: answered ? null : () => onAnswer(value),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: filled ? color : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: picked == value ? 2.5 : 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(value ? Icons.check_rounded : Icons.close_rounded, color: fg),
              const SizedBox(width: 6),
              Text(
                value ? S.of(context).test_true : S.of(context).test_false,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
