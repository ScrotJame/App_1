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
import '../widgets/ui_test_components.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TestScreenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: testScreenAppBar(title: Text(S.of(context).test_result_title)),
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
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(context, s),
                  const SizedBox(height: 14),
                  _buildStats(context, s),
                  const SizedBox(height: 14),
                  if (stats.length > 1) ...[
                    _buildKindStats(context, stats),
                    const SizedBox(height: 14),
                  ],
                  _buildRewards(context, s),
                  const SizedBox(height: 14),
                  if (changes.isNotEmpty) ...[
                    TestScreenEyebrow(
                      label: S.of(context).test_level_changes,
                      dotColor: AppColors.xoayGold,
                    ),
                    const SizedBox(height: 10),
                    for (final change in changes)
                      LevelChangeTile(change: change, dark: true),
                    const SizedBox(height: 6),
                  ],
                  if (s.showLevelDownExplanation) ...[
                    TestScreenNote(
                      icon: Icons.info_outline_rounded,
                      color: AppColors.xoayMagenta,
                      text: S.of(context).test_level_down_explained,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (s.notDueCount > 0) ...[
                    TestScreenNote(
                      icon: Icons.schedule_rounded,
                      color: AppColors.xoayGoldDeep,
                      text: S.of(context).test_words_not_due(s.notDueCount),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (s.cappedCount > 0) ...[
                    TestScreenNote(
                      icon: Icons.event_available_rounded,
                      color: AppColors.xoayCyan,
                      text: S.of(context).test_words_capped(s.cappedCount),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  TestScreenPrimaryButton(
                    label: S.of(context).test_retry,
                    icon: Icons.replay_rounded,
                    onTap: cubit.retryTest,
                  ),
                  const SizedBox(height: 10),
                  TestScreenGhostButton(
                    label: S.of(context).test_change_setup,
                    icon: Icons.tune_rounded,
                    onTap: cubit.goToConfig,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => context.go(Routes.home),
                    child: Text(
                      S.of(context).test_done,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.xoayPaperDim,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.xoaySurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.xoayGold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.xoayGold.withValues(alpha: 0.18),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [AppColors.xoayGold, AppColors.xoayGoldDeep],
            ).createShader(rect),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                // Painted over by the gradient.
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S
                .of(context)
                .test_result_correct_of(s.correctCount, s.totalQuestions),
            style: const TextStyle(color: AppColors.xoayPaperDim, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.xoayLine,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [AppColors.xoayGold, AppColors.xoayMagenta],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, TestState s) {
    Widget cell(IconData icon, Color color, String label, String value) {
      return Expanded(
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(vertical: 16),
          radius: 18,
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.xoayPaperDim)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell(Icons.check_circle_rounded, AppColors.xoayCyan,
            S.of(context).test_stat_correct, '${s.correctCount}'),
        const SizedBox(width: 10),
        cell(Icons.cancel_rounded, AppColors.xoayMagenta,
            S.of(context).test_stat_wrong, '${s.incorrectCount}'),
        const SizedBox(width: 10),
        cell(Icons.star_rounded, AppColors.xoayGold,
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
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TestScreenEyebrow(label: S.of(context).test_by_kind),
          const SizedBox(height: 12),
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
        color: AppColors.xoayCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.xoayCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(kind.icon, size: 18, color: AppColors.xoayCyan),
          const SizedBox(height: 4),
          Text(
            '${stat.correct}/${stat.total}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.xoayPaper,
            ),
          ),
          Text(
            kind.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.xoayPaperDim),
          ),
        ],
      ),
    );
  }

  Widget _buildRewards(BuildContext context, TestState s) {
    Widget item(String image, String text, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(image, width: 18, height: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        );

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.xoayGold.withValues(alpha: 0.08),
      borderColor: AppColors.xoayGold.withValues(alpha: 0.3),
      child: Column(
        children: [
          TestScreenEyebrow(
            label: S.of(context).test_rewards,
            dotColor: AppColors.xoayGold,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              item(
                  AppImages.imgGem,
                  S.of(context).test_reward_gems(s.gemsEarned),
                  AppColors.xoayCyan),
              const SizedBox(width: 38),
              item(AppImages.icStarXp, S.of(context).test_reward_xp(s.xpEarned),
                  AppColors.xoayGold),
            ],
          ),
        ],
      ),
    );
  }
}
