import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../commons/enums.dart';
import '../daily_quest_cubit.dart';
import '../models/daily_quest_model.dart';

/// ─── DAILY QUEST CARD ───────────────────────────────────────────────
/// Widget card hiển thị 3 nhiệm vụ hàng ngày.
/// Thay thế _buildPersonalizationBanner trong LearningHistoryPage.
///
/// Thiết kế:
/// ┌──────────────────────────────────────┐
/// │ 🎯 Nhiệm vụ hàng ngày     2/3 ✓    │
/// │ ━━━━━━━━━━━━━━━━━━━━━━━━━  67%      │
/// │                                      │
/// │ ☀️ Khởi động ngày mới        ✅      │
/// │ 📚 Học 5 từ mới          3/5  ▓▓░░  │
/// │ 🎯 Hoàn thành 1 quiz    0/1  ░░░░  │
/// └──────────────────────────────────────┘
class DailyQuestCard extends StatelessWidget {
  const DailyQuestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyQuestCubit, DailyQuestState>(
      builder: (context, state) {
        // Chưa load xong → shimmer loading
        if (state.loadStatus == LOADSTATUS.INITAL ||
            state.loadStatus == LOADSTATUS.LOADING) {
          return _buildShimmer();
        }

        // Lỗi → ẩn card (không crash page)
        if (state.loadStatus == LOADSTATUS.FAILED) {
          return const SizedBox.shrink();
        }

        return _buildCard(state);
      },
    );
  }

  // ─── MAIN CARD ─────────────────────────────────────────────

  Widget _buildCard(DailyQuestState state) {
    // Gradient đổi màu khi hoàn thành tất cả
    final gradientColors = state.allCompleted
        ? [const Color(0xFF10B981), const Color(0xFF059669)] // Emerald green
        : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]; // Blue

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state),
          const SizedBox(height: 12),
          _buildOverallProgress(state),
          const SizedBox(height: 14),
          ...state.quests.map((q) => _buildQuestItem(q)),
        ],
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────

  Widget _buildHeader(DailyQuestState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              state.allCompleted ? Icons.emoji_events : Icons.flag_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              state.allCompleted
                  ? 'Hoàn thành xuất sắc!'
                  : 'Nhiệm vụ hàng ngày',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${state.completedCount}/${state.quests.length} ✓',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ─── OVERALL PROGRESS BAR ──────────────────────────────────

  Widget _buildOverallProgress(DailyQuestState state) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: state.overallProgress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${state.completedCount} nhiệm vụ hoàn thành',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(state.overallProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── QUEST ITEM ────────────────────────────────────────────

  Widget _buildQuestItem(DailyQuestModel quest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: quest.isCompleted ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Icon
            Text(quest.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),

            // Title + progress text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: quest.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    quest.description,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: quest.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Mini progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: quest.progress),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            quest.isCompleted
                                ? const Color(0xFF34D399) // light emerald
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Progress count or checkmark
            quest.isCompleted
                ? Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : Text(
                    '${quest.currentValue}/${quest.targetValue}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ─── SHIMMER LOADING ───────────────────────────────────────

  Widget _buildShimmer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.3),
            const Color(0xFF1D4ED8).withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      ),
    );
  }
}
