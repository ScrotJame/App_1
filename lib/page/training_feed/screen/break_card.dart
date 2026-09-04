import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/page/training_feed/widgets/shared_widgets.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';
import 'package:test_abc/page/training_feed/widgets/widget_card_common.dart';

class BreakCard extends StatelessWidget {
  const BreakCard({super.key, required this.card});

  final TrainingFeedCard card;

  @override
  Widget build(BuildContext context) {
    return CardShell(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Eyebrow(
              label: S.of(context).break_eyebrow,
              dotColor: AppColors.xoayPaperDim,
            ),
            const SizedBox(height: 18),
            const Icon(Icons.flag_rounded, color: AppColors.xoayPaper, size: 52),
            const SizedBox(height: 22),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.xoayPaper,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              card.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.xoayPaper.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            XoayButton(
              label: S.of(context).leave,
              icon: Icons.check_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}