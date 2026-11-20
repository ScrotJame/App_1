import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../../test_word/widgets/button_widget.dart';
import '../daily_review_cubit.dart';
import '../logic/daily_review_question.dart';
import '../widgets/practice_note.dart';
import '../widgets/review_choice_tile.dart';
import '../widgets/review_word_card.dart';

class DailyReviewTestingScreen extends StatelessWidget {
  const DailyReviewTestingScreen({super.key});

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyReviewCubit, DailyReviewState>(
      buildWhen: (p, c) =>
          p.currentIndex != c.currentIndex ||
          p.selectedAnswerIndex != c.selectedAnswerIndex ||
          p.isSubmitting != c.isSubmitting ||
          p.questions != c.questions ||
          p.mode != c.mode,
      builder: (context, state) {
        final question = state.currentQuestion;
        if (question == null) return const SizedBox.shrink();
        return Column(
          children: [
            _buildProgress(state),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.isPractice) ...[
                      const PracticeNote(),
                      const SizedBox(height: 12),
                    ],
                    ReviewWordCard(question: question),
                    const SizedBox(height: 20),
                    ..._buildChoices(context, state, question),
                  ],
                ),
              ),
            ),
            if (state.hasAnsweredCurrent)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: buildPrimaryButton(
                  label: state.isLastQuestion
                      ? S.of(context).daily_review_finish
                      : S.of(context).daily_review_next,
                  icon: Icons.arrow_forward_rounded,
                  loading: state.isSubmitting,
                  onTap: () => context.read<DailyReviewCubit>().next(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgress(DailyReviewState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 6,
                color: AppColors.kBlue,
                backgroundColor: AppColors.kBlueMid,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${state.currentIndex + 1}/${state.questions.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.kBlue,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChoices(BuildContext context, DailyReviewState state,
      DailyReviewQuestion question) {
    final answered = state.hasAnsweredCurrent;
    return [
      for (var i = 0; i < question.choices.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ReviewChoiceTile(
            label: _labels[i],
            text: question.choices[i],
            state: !answered
                ? ReviewChoiceState.idle
                : i == question.correctIndex
                    ? ReviewChoiceState.correct
                    : i == state.selectedAnswerIndex
                        ? ReviewChoiceState.wrong
                        : ReviewChoiceState.idle,
            onTap: answered || state.isSubmitting
                ? null
                : () => context.read<DailyReviewCubit>().selectAnswer(i),
          ),
        ),
    ];
  }
}
