import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/models/entity/achivement_entity.dart';
import 'package:test_abc/ultis/extension/achievement_l10n_extension.dart';

import '../../../generated/l10n.dart';

class AchievementCardWidget extends StatelessWidget {
  final AchivementEntity achievement;

  const AchievementCardWidget({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked ?? false;
    final current = achievement.currentValue ?? 0;
    final target = achievement.targetValue ?? 1;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).getLocalizedAchievement(achievement.titleKey ?? ''),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.of(context).getLocalizedAchievement(achievement.descriptionKey ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (isUnlocked)
                  _buildUnlockedBadge()
                else
                  _buildProgressBar(progress, current, target),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final color = _colorFromCategory(achievement.category ?? '');
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _iconFromKey(achievement.iconKey ?? ''),
        size: 22,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressBar(double progress, int current, int target) {
    final color = _colorFromCategory(achievement.category ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$current / $target',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedBadge() {
    final dateStr = achievement.unlockedAt != null
        ? DateFormat('dd MMM').format(achievement.unlockedAt!)
        : '';
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF0F6E56)),
        const SizedBox(width: 4),
        Text(
          dateStr.isNotEmpty
              ? '${S.current.unlocked} · $dateStr'
              : S.current.unlocked,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F6E56),
          ),
        ),
      ],
    );
  }

  Color _colorFromCategory(String category) {
    switch (category) {
      case 'milestone':
        return const Color(0xFF185FA5);
      case 'streak':
        return const Color(0xFFBA7517);
      case 'collection':
        return const Color(0xFF0F6E56);
      case 'special':
        return const Color(0xFF534AB7);
      default:
        return const Color(0xFF185FA5);
    }
  }

  IconData _iconFromKey(String key) {
    switch (key) {
      case 'book':
        return Icons.menu_book_outlined;
      case 'users':
        return Icons.group_outlined;
      case 'moon':
        return Icons.nightlight_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      case 'star':
        return Icons.star_outline_rounded;
      case 'trophy':
        return Icons.emoji_events_outlined;
      default:
        return Icons.workspace_premium_outlined;
    }
  }
}