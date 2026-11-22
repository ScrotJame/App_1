import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../commons/app_colors.dart';
import '../../../commons/app_images.dart';
import '../../../commons/enums.dart';
import '../../../generated/l10n.dart';
import '../../../router/router.dart';
import '../../daily_review/daily_review_cubit.dart' show DailyReviewWordChange;
import '../../daily_review/widgets/level_change_tile.dart';
import '../test_cubit.dart';
import '../test_kind_text.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/card_widget.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kSurface,
      appBar: SimpleAppBar(S.of(context).test_result_title),
      body: BlocBuilder<TestCubit, TestState>(
        builder: (context, s) {
          final cubit = context.read<TestCubit>();
          final stats = s.kindStats;
          final changes = [
            for (final c in [...s.leveledUpWords, ...s.leveledDownWords])
              DailyReviewWordChange(
                wordId: c.word.id,
                word: c.word.word,
                meaning: c.word.meaning,
                before: c.previousLevel,
                after: c.word.level,
              ),
          ];
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(context, s),
                const SizedBox(height: 16),
                _buildStats(context, s),
                const SizedBox(height: 16),
                if (stats.length > 1) ...[
                  _buildKindStats(context, stats),
                  const SizedBox(height: 16),
                ],
                _buildRewards(context, s),
                const SizedBox(height: 16),
                if (changes.isNotEmpty) ...[
                  Text(
                    S.of(context).test_level_changes,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final change in changes) LevelChangeTile(change: change),
                  const SizedBox(height: 8),
                ],
                if (s.showLevelDownExplanation) ...[
                  _buildNote(Icons.info_outline_rounded, AppColors.kRed,
                      S.of(context).test_level_down_explained),
                  const SizedBox(height: 12),
                ],
                if (s.notDueCount > 0) ...[
                  _buildNote(Icons.schedule_rounded, AppColors.kAmber,
                      S.of(context).test_words_not_due(s.notDueCount)),
                  const SizedBox(height: 12),
                ],
                if (s.cappedCount > 0) ...[
                  _buildNote(Icons.event_available_rounded, AppColors.kBlue,
                      S.of(context).test_words_capped(s.cappedCount)),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                buildPrimaryButton(
                  label: S.of(context).test_retry,
                  icon: Icons.replay_rounded,
                  onTap: cubit.retryTest,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: cubit.goToConfig,
                    icon: const Icon(Icons.tune_rounded, size: 17),
                    label: Text(
                      S.of(context).test_change_setup,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kBlue,
                      side: const BorderSide(color: AppColors.kBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text(
                    S.of(context).test_done,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context, TestState s) {
    final pct = s.totalQuestions == 0 ? 0.0 : s.correctCount / s.totalQuestions;
    final (emoji, message) = pct >= 0.9
        ? ('🏆', S.of(context).test_result_excellent)
        : pct >= 0.7
            ? ('🎉', S.of(context).test_result_good)
            : pct >= 0.5
                ? ('📚', S.of(context).test_result_keep_going)
                : ('💪', S.of(context).test_result_review_more);
    return GradientCard(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context).test_result_correct_of(s.correctCount, s.totalQuestions),
            style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppColors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, TestState s) {
    Widget cell(IconData icon, Color color, String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.kTextMuted)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell(Icons.check_circle_rounded, AppColors.kGreen,
            S.of(context).test_stat_correct, '${s.correctCount}'),
        const SizedBox(width: 10),
        cell(Icons.cancel_rounded, AppColors.kRed,
            S.of(context).test_stat_wrong, '${s.incorrectCount}'),
        const SizedBox(width: 10),
        cell(Icons.star_rounded, AppColors.kAmber,
            S.of(context).test_stat_score, '${s.score}'),
      ],
    );
  }

  Widget _buildKindStats(
    BuildContext context,
    Map<TestKind, ({int correct, int total})> stats,
  ) {
    final kinds = [
      for (final kind in TestKind.values)
        if (stats.containsKey(kind)) kind,
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).test_by_kind,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < kinds.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildKindCell(
                    kinds[i],
                    stats[kinds[i]] ?? (correct: 0, total: 0),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKindCell(TestKind kind, ({int correct, int total}) stat) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.kBlueBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(kind.icon, size: 18, color: AppColors.kBlue),
          const SizedBox(height: 4),
          Text(
            '${stat.correct}/${stat.total}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
          ),
          Text(
            kind.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRewards(BuildContext context, TestState s) {
    Widget item(String image, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(image, width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.kTextMuted,
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Text(
            S.of(context).test_rewards,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.kGreen,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              item(AppImages.imgGem, S.of(context).test_reward_gems(s.gemsEarned)),
              const SizedBox(width: 38),
              item(AppImages.icStarXp, S.of(context).test_reward_xp(s.xpEarned)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNote(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
