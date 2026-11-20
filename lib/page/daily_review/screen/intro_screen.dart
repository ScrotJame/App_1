import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../../test_word/widgets/button_widget.dart';
import '../../test_word/widgets/card_widget.dart';
import '../daily_review_cubit.dart';
import '../data/daily_review_session.dart';
import '../logic/daily_review_picker.dart';
import '../widgets/preset_sheet.dart';

class DailyReviewIntroScreen extends StatelessWidget {
  const DailyReviewIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyReviewCubit, DailyReviewState>(
      buildWhen: (p, c) =>
          p.session != c.session ||
          p.preset != c.preset ||
          p.isSubmitting != c.isSubmitting,
      builder: (context, state) {
        final session = state.session;
        if (session == null) return const SizedBox.shrink();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, session),
              const SizedBox(height: 16),
              _buildGroups(context, session),
              const SizedBox(height: 16),
              _buildMode(context, session, state.preset),
              const SizedBox(height: 12),
              _buildWarning(context),
              const SizedBox(height: 24),
              if (session.isCompleted) ...[
                _buildCompletedSummary(context, session),
                const SizedBox(height: 16),
                buildPrimaryButton(
                  label: S.of(context).daily_review_practice_again,
                  icon: Icons.replay_rounded,
                  loading: state.isSubmitting,
                  onTap: () => context.read<DailyReviewCubit>().practice(),
                ),
              ] else
                buildPrimaryButton(
                  label: session.answeredCount == 0
                      ? S.of(context).daily_review_start
                      : S.of(context).daily_review_continue(
                          session.answeredCount, session.total),
                  icon: Icons.play_arrow_rounded,
                  loading: state.isSubmitting,
                  onTap: () => context.read<DailyReviewCubit>().start(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DailyReviewSession session) {
    return GradientCard(
      child: Row(
        children: [
          const Icon(Icons.fact_check_rounded, color: AppColors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              S.of(context).daily_review_word_count(session.total),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroups(BuildContext context, DailyReviewSession session) {
    final s = S.of(context);
    final rest = session.groupCount(DailyReviewGroup.rest);
    final labels = [
      s.daily_review_group_due(session.groupCount(DailyReviewGroup.due)),
      s.daily_review_group_weak(session.groupCount(DailyReviewGroup.weak)),
      s.daily_review_group_mastered(
          session.groupCount(DailyReviewGroup.mastered)),
      if (rest > 0) s.daily_review_group_rest(rest),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          Chip(
            label: Text(label),
            backgroundColor: AppColors.kBlueBg,
            side: const BorderSide(color: AppColors.kBorder),
            labelStyle: const TextStyle(
              color: AppColors.kBlue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildMode(
      BuildContext context, DailyReviewSession session, int preset) {
    final s = S.of(context);
    return Row(
      children: [
        const Icon(Icons.tune_rounded, color: AppColors.kBlue, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            session.adaptive
                ? s.daily_review_mode_adaptive(session.target)
                : s.daily_review_mode_preset(session.target),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _pickPreset(context, preset),
          child: Text(s.daily_review_words_per_day),
        ),
      ],
    );
  }

  Future<void> _pickPreset(BuildContext context, int current) async {
    final cubit = context.read<DailyReviewCubit>();
    final selected = await showDailyReviewPresetSheet(context, current: current);
    if (selected != null) await cubit.changePreset(selected);
  }

  Widget _buildWarning(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppColors.kAmber, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            S.of(context).daily_review_wrong_warning,
            style: const TextStyle(
              color: AppColors.kAmber,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedSummary(
      BuildContext context, DailyReviewSession session) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kGreen),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.kGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).daily_review_done_summary(
                  session.correctCount, session.answeredCount),
              style: const TextStyle(
                color: AppColors.kGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
