import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';

import '../../../generated/l10n.dart';

class AchievementFilterBarWidget extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const AchievementFilterBarWidget({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static final List<_FilterItem> _filters = [
    _FilterItem(key: null, labelKey: S.current.filter_all),
    _FilterItem(key: 'milestone', labelKey: S.current.filter_milestone),
    _FilterItem(key: 'streak', labelKey: S.current.filter_streak),
    _FilterItem(key: 'collection', labelKey: S.current.filter_collection),
    _FilterItem(key: 'special', labelKey: S.current.filter_special),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = _filters[i];
          final isActive = selected == item.key;
          return _FilterChip(
            label: S.current.filterLabel(item.labelKey),
            isActive: isActive,
            onTap: () => onSelect(item.key),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterItem {
  final String? key;
  final String labelKey;
  const _FilterItem({required this.key, required this.labelKey});
}