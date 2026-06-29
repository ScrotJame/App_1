import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';

import '../../../commons/app_colors.dart';

class CardShell extends StatelessWidget {
  const CardShell({
    required this.child,
    this.event = const TrainingFeedEvent.none(),
    this.shimmer = false,
  });

  final Widget child;
  final TrainingFeedEvent event;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: shimmer
              ? AppColors.xoayGold.withOpacity(0.25)
              : Colors.white.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (event.isActive)
            Align(
              alignment: Alignment.topCenter,
              child: EventBadge(event: event),
            ),
          Padding(
            padding: EdgeInsets.only(top: event.isActive ? 42 : 0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class EventBadge extends StatelessWidget {
  const EventBadge({required this.event});

  final TrainingFeedEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.xoayGold, AppColors.xoayMagenta],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '${event.title} x${event.multiplier.toStringAsFixed(event.multiplier == event.multiplier.roundToDouble() ? 0 : 2)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}


class Eyebrow extends StatelessWidget {
  const Eyebrow({required this.label, this.dotColor = AppColors.xoayCyan});

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.xoayPaper.withOpacity(0.58),
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}