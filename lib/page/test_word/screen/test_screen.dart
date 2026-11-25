import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../commons/app_colors.dart';
import '../../../generated/l10n.dart';
import '../test_cubit.dart';
import '../widgets/question/answer_feedback_bar.dart';
import '../widgets/question/choice_question_view.dart';
import '../widgets/question/hint_button.dart';
import '../widgets/question/listening_question_view.dart';
import '../widgets/question/test_progress_header.dart';
import '../widgets/question/timer_badge.dart';
import '../widgets/question/true_false_question_view.dart';
import '../widgets/question/typing_question_view.dart';
import '../widgets/ui_test_components.dart';

class TestingScreen extends StatelessWidget {
  const TestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TestScreenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            BlocBuilder<TestCubit, TestState>(
              buildWhen: (p, c) =>
                  p.currentIndex != c.currentIndex ||
                  p.score != c.score ||
                  p.questions != c.questions,
              builder: (_, s) => TestProgressHeader(
                progress: s.progressPercent,
                score: s.score,
                kind: s.currentQuestion?.kind,
              ),
            ),
            Expanded(
              child: BlocBuilder<TestCubit, TestState>(
                buildWhen: (p, c) =>
                    p.questions != c.questions ||
                    p.currentIndex != c.currentIndex ||
                    p.answers != c.answers ||
                    p.eliminatedIndexes != c.eliminatedIndexes ||
                    p.revealedChars != c.revealedChars,
                builder: (context, s) {
                  final q = s.currentQuestion;
                  if (q == null) return const SizedBox();
                  // A new question gets fresh widgets (text field, audio) and
                  // a scroll view back at the top.
                  return SingleChildScrollView(
                    key: ValueKey(s.currentIndex),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: _buildQuestion(context, s, q),
                  );
                },
              ),
            ),
            BlocBuilder<TestCubit, TestState>(
              buildWhen: (p, c) =>
                  p.currentIndex != c.currentIndex ||
                  p.answers != c.answers ||
                  p.hintsUsed != c.hintsUsed ||
                  p.isLevelingUp != c.isLevelingUp ||
                  p.eliminatedIndexes != c.eliminatedIndexes ||
                  p.revealedChars != c.revealedChars,
              builder: (context, s) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
                child: KeyedSubtree(
                  key: ValueKey('${s.currentIndex}-${s.hasAnsweredCurrent}'),
                  child: _buildBottom(context, s),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return testScreenAppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.xoayPaper),
        onPressed: () => context.read<TestCubit>().goToConfig(),
      ),
      title: BlocBuilder<TestCubit, TestState>(
        buildWhen: (p, c) =>
            p.currentIndex != c.currentIndex ||
            p.totalQuestions != c.totalQuestions,
        builder: (context, s) => Text(
          S
              .of(context)
              .test_question_progress(s.currentIndex + 1, s.totalQuestions),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.xoayPaper,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
      actions: [
        BlocBuilder<TestCubit, TestState>(
          buildWhen: (p, c) =>
              p.remainingSeconds != c.remainingSeconds ||
              p.config.enableTimer != c.config.enableTimer,
          builder: (_, s) {
            if (!s.config.enableTimer) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: TimerBadge(
                  text: s.formattedTime,
                  warning: s.isTimerWarning,
                  critical: s.isTimerCritical,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, TestState s, TestQuestion q) {
    final cubit = context.read<TestCubit>();
    final answer = s.currentAnswer;
    return switch (q) {
      final ChoiceQuestion question => ChoiceQuestionView(
          question: question,
          answer: answer,
          eliminated: s.currentEliminatedIndexes,
          onSelect: (i) => cubit.submitAnswer(ChoiceAnswer(i)),
        ),
      final ListeningQuestion question => ListeningQuestionView(
          question: question,
          answer: answer,
          eliminated: s.currentEliminatedIndexes,
          onSelect: (i) => cubit.submitAnswer(ChoiceAnswer(i)),
        ),
      final TrueFalseQuestion question => TrueFalseQuestionView(
          question: question,
          answer: answer,
          onAnswer: (value) => cubit.submitAnswer(BoolAnswer(value)),
        ),
      final TypingQuestion question => TypingQuestionView(
          question: question,
          answer: answer,
          revealed: s.currentRevealedChars,
          onSubmit: (text) => cubit.submitAnswer(TextAnswer(text)),
        ),
    };
  }

  Widget _buildBottom(BuildContext context, TestState s) {
    final cubit = context.read<TestCubit>();
    final q = s.currentQuestion;
    final answer = s.currentAnswer;
    if (q == null) return const SizedBox();
    if (answer != null) {
      return AnswerFeedbackBar(
        question: q,
        answer: answer,
        isCorrect: s.isCurrentCorrect,
        isLast: s.isLastQuestion,
        loading: s.isLevelingUp,
        onNext: cubit.nextQuestion,
      );
    }
    return TestScreenBottomBar(
      child: Row(
        children: [
          HintButton(
            remaining: s.hintsRemaining,
            enabled: s.canUseHint,
            onTap: cubit.useHint,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
