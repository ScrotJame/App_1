import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../../commons/app_colors.dart';
import '../../../router/router.dart';
import '../../test_word/widgets/button_widget.dart';
import '../../test_word/widgets/card_widget.dart';
import '../daily_review_cubit.dart';
import '../logic/daily_review_rewards.dart';
import '../widgets/level_change_tile.dart';
import '../widgets/practice_note.dart';
import '../widgets/reward_row.dart';

class DailyReviewResultScreen extends StatelessWidget {
  const DailyReviewResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyReviewCubit, DailyReviewState>(
      buildWhen: (p, c) =>
          p.session != c.session ||
          p.mode != c.mode ||
          p.practiceAnswers != c.practiceAnswers ||
          p.wordChanges != c.wordChanges ||
          p.reward != c.reward ||
          p.isSubmitting != c.isSubmitting,
      builder: (context, state) {
        final s = S.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScore(context, state),
              const SizedBox(height: 16),
              if (state.isPractice)
                const PracticeNote()
              else ...[
                _buildChanges(s.daily_review_leveled_up, state.leveledUp),
                _buildChanges(s.daily_review_leveled_down, state.leveledDown),
                if (state.wordChanges.isEmpty)
                  Text(
                    s.daily_review_no_change,
                    style: TextStyle(
                        color: AppColors.textBlack.withValues(alpha: 0.55)),
                  ),
                const SizedBox(height: 16),
                _buildRewards(context, state.reward),
              ],
              const SizedBox(height: 24),
              buildPrimaryButton(
                label: s.daily_review_practice_again,
                icon: Icons.replay_rounded,
                loading: state.isSubmitting,
                onTap: () => context.read<DailyReviewCubit>().practice(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go(Routes.home),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.kBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    s.daily_review_back_home,
                    style: const TextStyle(
                      color: AppColors.kBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScore(BuildContext context, DailyReviewState state) {
    return GradientCard(
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              S.of(context).daily_review_result_score(
                  state.resultCorrect, state.resultTotal),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChanges(String title, List<DailyReviewWordChange> changes) {
    if (changes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          for (final change in changes) LevelChangeTile(change: change),
        ],
      ),
    );
  }

  Widget _buildRewards(
      BuildContext context, DailyReviewRewardBreakdown reward) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.daily_review_reward_title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textBlack,
            ),
          ),
          if (reward.wordXp > 0 || reward.wordGems > 0)
            RewardRow(
              label: s.daily_review_reward_words,
              xp: reward.wordXp,
              gems: reward.wordGems,
            ),
          RewardRow(
            label: s.daily_review_reward_completion,
            xp: reward.completionXp,
            gems: reward.completionGems,
          ),
          if (reward.accuracyXp > 0 || reward.accuracyGems > 0)
            RewardRow(
              label: s.daily_review_reward_accuracy,
              xp: reward.accuracyXp,
              gems: reward.accuracyGems,
            ),
        ],
      ),
    );
  }
}
