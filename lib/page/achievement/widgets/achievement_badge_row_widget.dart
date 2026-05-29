import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/models/entity/achivement_entity.dart';
import 'package:test_abc/ultis/extension/achievement_l10n_extension.dart';

import '../../../generated/l10n.dart';

class AchievementBadgeRowWidget extends StatelessWidget {
  final List<AchivementEntity> badges;
  final VoidCallback? onViewAll;

  const AchievementBadgeRowWidget({
    super.key,
    required this.badges,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildBadgeList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          S.current.recent_badges,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            S.current.view_all,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: badges
            .map((badge) => _BadgeItemWidget(badge: badge))
            .toList(),
      ),
    );
  }
}

class _BadgeItemWidget extends StatelessWidget {
  final AchivementEntity badge;

  const _BadgeItemWidget({required this.badge});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked ?? false;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                border: Border.all(
                  color: isUnlocked ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Icon(
                isUnlocked
                    ? _iconFromKey(badge.iconKey ?? '')
                    : Icons.lock_outline_rounded,
                size: 22,
                color: isUnlocked ? AppColors.primary : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.of(context).getLocalizedAchievement(badge.titleKey ?? ''),
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFromKey(String key) {
    switch (key) {
      case 'trophy':
        return Icons.emoji_events_outlined;
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'language':
        return Icons.translate_outlined;
      case 'star':
        return Icons.star_outline_rounded;
      case 'fire':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.workspace_premium_outlined;
    }
  }
}