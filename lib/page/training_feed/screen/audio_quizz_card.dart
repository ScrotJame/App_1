import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';
import 'package:test_abc/page/training_feed/widgets/widget_card_common.dart';

import '../../../commons/app_colors.dart';
import '../training_feed_cubit.dart';
import '../widgets/quiz_option.dart';

class AudioQuizCard extends StatelessWidget {
  const AudioQuizCard({
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
          Eyebrow(label: S.of(context).audio_quiz_eyebrow, dotColor: AppColors.xoayMagenta),
          const SizedBox(height: 16),
          Text(
            card.title,
            style: const TextStyle(
              color: AppColors.xoayPaper,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          // ── Nút loa to, bấm để nghe / nghe lại ──
          Center(
            child: GestureDetector(
              onTap: () {
                context.read<TrainingFeedCubit>().pronounceCurrentWord();
              },
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.xoayMagenta, AppColors.xoayCyan],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.xoayMagenta.withOpacity(0.35),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
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
                  context.read<TrainingFeedCubit>().answerAudioQuiz(index);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}