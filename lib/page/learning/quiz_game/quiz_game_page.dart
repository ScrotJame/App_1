import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/enums.dart';
import '../../../models/quiz_models.dart';
import '../../../repository/vocabulary_repository.dart';
import '../learning_cubit.dart';
import 'quiz_game_cubit.dart';
import 'widgets/battle_scene.dart';

class QuizGamePage extends StatefulWidget {
  const QuizGamePage({super.key});

  @override
  State<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends State<QuizGamePage>
    with TickerProviderStateMixin {
  late QuizGameCubit _cubit;
  StreamSubscription<String>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    final config = context.read<LearningCubit>().state.config;
    _cubit = QuizGameCubit(
      context.read<VocabularyRepository>(),
      config: config,
    );
    _messageSubscription = _cubit.messageController.stream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _cubit.start();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<QuizGameCubit, QuizGameState>(
            listenWhen: (prev, cur) =>
                prev.quizStatus != cur.quizStatus &&
                cur.quizStatus == QuizStatus.completed,
            listener: (context, state) {
              _showResultDialog(context, state);
            },
            builder: (context, state) {
              if (state.loadStatus == LOADSTATUS.LOADING ||
                  state.loadStatus == LOADSTATUS.INITAL) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state.loadStatus == LOADSTATUS.FAILED) {
                return _buildFailureWidget(state);
              }

              final question = state.currentQuestion;
              if (question == null) return const SizedBox.shrink();

              return Column(
                children: [
                  _buildHeaderWidget(state),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const SizedBox(height: 20),
                          BattleScene(state: state),
                          const SizedBox(height: 24),
                          _buildWordAttackWidget,
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildQuestionTextWidget(question),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildAnswerGridWidget(state, question),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeaderWidget(QuizGameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Progress section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${state.displayIndex} of ${state.totalQuestions}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (Image Card replaced by BattleScene)

  // ═══════════════════════════════════════════════════════════════
  // QUESTION TEXT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuestionTextWidget(QuizQuestion question) {
    return Text(
      question.questionText,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget get _buildWordAttackWidget {
    final question = _cubit.state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '「 ${question.word} 」',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════
  // ANSWER GRID
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAnswerGridWidget(QuizGameState state, QuizQuestion question) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        return _buildAnswerItemWidget(state, option);
      },
    );
  }

  Widget _buildAnswerItemWidget(QuizGameState state, AnswerOption option) {
    final isSelected = state.selectedAnswerId == option.id;
    final isAnswered = state.quizStatus == QuizStatus.answered;

    // Determine card style based on state
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;
    Color? iconColor;

    if (!isAnswered) {
      // Not yet answered
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF334155);
      trailingIcon = null;
    } else if (isSelected && option.isCorrect) {
      // Correct answer selected
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF86EFAC);
      textColor = const Color(0xFF166534);
      trailingIcon = Icons.check_circle;
      iconColor = AppColors.kGreen;
    } else if (isSelected && !option.isCorrect) {
      // Wrong answer selected
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFF991B1B);
      trailingIcon = Icons.cancel;
      iconColor = AppColors.kRed;
    } else if (option.isCorrect) {
      // Correct but not selected (reveal)
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF86EFAC);
      textColor = const Color(0xFF166534);
      trailingIcon = Icons.check_circle;
      iconColor = AppColors.kGreen;
    } else {
      // Other wrong options
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF94A3B8);
      trailingIcon = null;
    }

    return GestureDetector(
      onTap: isAnswered ? null : () => _cubit.selectAnswer(option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            if (trailingIcon != null) ...[
              Icon(trailingIcon, color: iconColor, size: 24),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Center(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FAILURE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFailureWidget(QuizGameState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.kRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              state.errorMessage ?? 'Tải dữ liệu thất bại',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _cubit.start(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(S.of(context).retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RESULT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showResultDialog(BuildContext context, QuizGameState state) {
    final percentage = state.totalQuestions > 0
        ? ((state.correctCount / state.totalQuestions) * 100).toInt()
        : 0;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: percentage >= 70
                        ? [const Color(0xFF4ADE80), const Color(0xFF16A34A)]
                        : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    percentage >= 70 ? '🎉' : '💪',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                percentage >= 70 ? 'Excellent!' : 'Keep Practicing!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You got ${state.correctCount}/${state.totalQuestions} correct ($percentage%)',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('✅', '${state.correctCount}', 'Correct'),
                  _buildStatItem('❌', '${state.wrongCount}', 'Wrong'),
                  _buildStatItem(
                    '📊',
                    '$percentage%',
                    'Score',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Restart button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _cubit.restart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Back button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.maybePop(context);
                },
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
