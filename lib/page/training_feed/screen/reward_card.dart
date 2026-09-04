import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/page/training_feed/training_feed_cubit.dart';
import 'package:test_abc/page/training_feed/widgets/shared_widgets.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';
import 'package:test_abc/page/training_feed/widgets/widget_card_common.dart';

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.card,
  });

  final TrainingFeedCard card;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      shimmer: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Eyebrow(label: S.of(context).jackpot, dotColor: AppColors.xoayGold),
            const SizedBox(height: 18),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.xoayGold, AppColors.xoayGoldDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.xoayGold.withOpacity(0.35),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Text(
                S.of(context).today_surprise,
                style: const TextStyle(
                  color: Color(0xFF0B0A14),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Reward details (Dynamic XP & Gems side-by-side)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (card.xpPreview > 0) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${card.xpPreview}',
                        style: const TextStyle(
                          color: AppColors.xoayGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context).bonus_xp,
                        style: TextStyle(
                          color: AppColors.xoayPaper.withOpacity(0.58),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
                if (card.xpPreview > 0 && card.gemsPreview > 0)
                  const SizedBox(width: 36),
                if (card.gemsPreview > 0) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${card.gemsPreview}',
                        style: const TextStyle(
                          color: AppColors.xoayCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context).gems_label,
                        style: TextStyle(
                          color: AppColors.xoayCyan.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),
            // Claim
            XoayButton(
              label: card.isCompleted
                  ? S.of(context).claimed
                  : S.of(context).claim_reward,
              icon: card.isCompleted
                  ? Icons.check_rounded
                  : Icons.card_giftcard_rounded,
              onTap: () {
                context.read<TrainingFeedCubit>().claimPassiveReward();
              },
            ),
          ],
        ),
      ),
    );
  }
}