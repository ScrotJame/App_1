import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../commons/app_colors.dart';
import '../test_cubit.dart';

enum _ChoiceState { idle, selected, correct, wrong, eliminated }

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  static const _choiceLabels = ['A', 'B', 'C', 'D'];

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTestAppBar() {
    return AppBar(
      toolbarHeight: 56,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black87),
        onPressed: () => context.read<TestCubit>().goToConfig(),
      ),
      title: BlocBuilder<TestCubit, TestState>(
        buildWhen: (p, c) =>
        p.currentIndex != c.currentIndex ||
            p.totalQuestions != c.totalQuestions,
        builder: (_, s) => RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
            children: [
              const TextSpan(text: 'Câu '),
              TextSpan(
                  text: '${s.currentIndex + 1}',
                  style: const TextStyle(color: AppColors.kBlue)),
              TextSpan(text: ' / ${s.totalQuestions}'),
            ],
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<TestCubit, TestState>(
          buildWhen: (p, c) => p.remainingSeconds != c.remainingSeconds,
          builder: (_, s) {
            if (!s.config.enableTimer) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTimerBadge(
                formattedTime: s.formattedTime,
                isWarning: s.isTimerWarning,
                isCritical: s.isTimerCritical,
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Timer badge ─────────────────────────────────────────────────────────────

  Widget _buildTimerBadge({
    required String formattedTime,
    required bool isWarning,
    required bool isCritical,
  }) {
    final Color bg;
    final Color fg;
    if (isCritical) {
      bg = const Color(0xFFFF3B30).withValues(alpha: 0.12);
      fg = const Color(0xFFFF3B30);
    } else if (isWarning) {
      bg = const Color(0xFFFF9500).withValues(alpha: 0.12);
      fg = const Color(0xFFFF9500);
    } else {
      bg = AppColors.kBlueBg;
      fg = AppColors.kBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(formattedTime,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }

  // ── Progress section ────────────────────────────────────────────────────────

  Widget _buildProgressSection() {
    return BlocBuilder<TestCubit, TestState>(
      buildWhen: (p, c) =>
      p.currentIndex != c.currentIndex || p.score != c.score,
      builder: (_, s) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${s.currentIndex + 1}/${s.totalQuestions}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                _buildScoreBadge(s.score),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.progressPercent,
                minHeight: 6,
                backgroundColor: AppColors.kBorder,
                valueColor: const AlwaysStoppedAnimation(AppColors.kBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Score badge ─────────────────────────────────────────────────────────────

  Widget _buildScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.kAmber),
          const SizedBox(width: 4),
          Text('$score điểm',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309))),
        ],
      ),
    );
  }

  // ── Word card ───────────────────────────────────────────────────────────────

  Widget _buildWordCard(TestQuestion q) {
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
            q.cardLabel.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.kBlue,
                letterSpacing: 1.2
            ),
          ),
          const SizedBox(height: 12),

          // HIỂN THỊ TỪ VỰNG / NGHĨA CHÍNH TẠI ĐÂY[cite: 2]
          Text(
            q.questionDisplay,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),

          if (q.pronunciationDisplay != null &&
              (q.pronunciationDisplay ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q.pronunciationDisplay ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () {/* TODO: TTS */},
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.kBlueMid, shape: BoxShape.circle),
              child: const Icon(Icons.volume_up_rounded,
                  color: AppColors.kBlue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Choice item ─────────────────────────────────────────────────────────────

  Widget _buildChoiceItem({
    required String label,
    required String text,
    required _ChoiceState state,
    VoidCallback? onTap,
  }) {
    Color border, bg, lblBg, lblFg, textFg;
    Widget? trailing;

    switch (state) {
      case _ChoiceState.selected:
        border = AppColors.kBlue; bg = Colors.white;
        lblBg = AppColors.kBlueMid; lblFg = AppColors.kBlue; textFg = Colors.black87;
        trailing = const Icon(Icons.radio_button_checked_rounded,
            color: AppColors.kBlue, size: 22);
        break;
      case _ChoiceState.correct:
        border = AppColors.kGreen; bg = const Color(0xFFF0FDF4);
        lblBg = const Color(0xFFDCFCE7); lblFg = AppColors.kGreen; textFg = AppColors.kGreen;
        trailing = const Icon(Icons.check_circle_rounded,
            color: AppColors.kGreen, size: 22);
        break;
      case _ChoiceState.wrong:
        border = AppColors.kRed; bg = const Color(0xFFFFF5F5);
        lblBg = const Color(0xFFFEE2E2); lblFg = AppColors.kRed; textFg = AppColors.kRed;
        trailing = const Icon(Icons.cancel_rounded, color: AppColors.kRed, size: 22);
        break;
      case _ChoiceState.eliminated:
        border = AppColors.kBorder; bg = const Color(0xFFF8FAFC);
        lblBg = const Color(0xFFF1F5F9); lblFg = Colors.grey; textFg = Colors.grey;
        trailing = null;
        break;
      default:
        border = AppColors.kBorder; bg = Colors.white;
        lblBg = AppColors.kBlueBg; lblFg = AppColors.kBlue; textFg = Colors.black87;
        trailing = const Icon(Icons.radio_button_unchecked_rounded,
            color: Colors.grey, size: 22);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: lblBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: lblFg)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textFg,
                      decoration: state == _ChoiceState.eliminated
                          ? TextDecoration.lineThrough
                          : null)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ── Choice list ─────────────────────────────────────────────────────────────

  Widget _buildChoiceList(BuildContext ctx, TestState s) {
    final q = s.currentQuestion;
    if (q == null) return const SizedBox();

    return Column(
      children: List.generate(q.choices.length, (i) {
        final isElim = s.currentEliminatedIndexes.contains(i);
        final isSel = s.selectedAnswerIndex == i;
        final answered = s.hasAnsweredCurrent;

        final cs = isElim
            ? _ChoiceState.eliminated
            : !answered
            ? (isSel ? _ChoiceState.selected : _ChoiceState.idle)
            : i == q.correctIndex
            ? _ChoiceState.correct
            : isSel
            ? _ChoiceState.wrong
            : _ChoiceState.idle;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildChoiceItem(
            label: _choiceLabels[i],
            text: q.choices[i],
            state: cs,
            onTap: (!answered && !isElim)
                ? () => ctx.read<TestCubit>().selectAnswer(i)
                : null,
          ),
        );
      }),
    );
  }

  // ── Hint button ─────────────────────────────────────────────────────────────

  Widget _buildHintBtn({
    required int remaining,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('💡', style: TextStyle(fontSize: 17)),
                  SizedBox(width: 6),
                  Text('Gợi ý',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                          fontSize: 13)),
                ],
              ),
            ),
            if (remaining > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: const BoxDecoration(
                      color: AppColors.kBlue, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$remaining',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Next button ─────────────────────────────────────────────────────────────

  Widget _buildNextBtn({
    required bool isLast,
    required bool loading,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled && !loading ? onTap : null,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
              color: AppColors.kBlue,
              borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isLast ? 'Xem kết quả' : 'Câu tiếp theo',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return BlocBuilder<TestCubit, TestState>(
      builder: (ctx, s) {
        final c = ctx.read<TestCubit>();
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -3))
            ],
          ),
          child: Row(
            children: [
              // _buildHintBtn(
              //   remaining: s.hintsRemaining,
              //   enabled: !s.hasAnsweredCurrent && s.hintsRemaining > 0,
              //   onTap: c.useHint,
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNextBtn(
                  isLast: s.isLastQuestion,
                  loading: s.isLevelingUp,
                  enabled: s.hasAnsweredCurrent,
                  onTap: c.nextQuestion,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kSurface,
      appBar: _buildTestAppBar(),
      body: Column(
        children: [
          _buildProgressSection(),
          Expanded(
            child: BlocBuilder<TestCubit, TestState>(
              buildWhen: (p, c) => p.currentIndex != c.currentIndex,
              builder: (ctx, s) {
                final q = s.currentQuestion;
                if (q == null) return const SizedBox();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWordCard(q),
                      const SizedBox(height: 14),
                      BlocBuilder<TestCubit, TestState>(
                        builder: (ctx2, s2) => _buildChoiceList(ctx2, s2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }
}