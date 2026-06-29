import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/page/training_feed/training_feed_cubit.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';
import 'package:test_abc/page/training_feed/widgets/widget_card_common.dart';

import '../widgets/quiz_option.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({
    required this.card,
  });

  final TrainingFeedCard card;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      event: card.event,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Eyebrow(label: S.of(context).quiz_eyebrow, dotColor: AppColors.xoayCyan),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.xoayPaper,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              children: [
                TextSpan(text: S.of(context).quiz_prefix),
                TextSpan(
                  text: card.title,
                  style: const TextStyle(
                    color: AppColors.xoayCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                TextSpan(text: S.of(context).quiz_suffix),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // ── 2x2 Grid ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: card.choices.length,
            itemBuilder: (context, index) {
              return QuizOption(
                label: card.choices[index],
                isSelected: card.selectedChoiceIndex == index,
                isCorrect: card.correctChoiceIndex == index,
                isAnswered: card.isAnswered,
                onTap: () {
                  context.read<TrainingFeedCubit>().answerCurrentQuiz(index);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}