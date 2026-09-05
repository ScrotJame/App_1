import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';

import '../../../generated/l10n.dart';

class AchievementSummaryWidget extends StatelessWidget {
  final int unlocked;
  final int total;
  final int completionPercent;
  final int totalXp;
  final int leagueRank;
  final int badgeCount;

  const AchievementSummaryWidget({
    super.key,
    required this.unlocked,
    required this.total,
    required this.completionPercent,
    required this.totalXp,
    required this.leagueRank,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsRow(context),
        const SizedBox(height: 12),
        _buildProgressBanner(context),
      ],
    );
  }

  // ── Stats row: XP / League / Badges ──────────────────────────
  Widget _buildStatsRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          _buildStatCell(
            context,
            value: _formatXp(totalXp),
            label: S.current.total_xp,
          ),
          _buildDivider(),
          _buildStatCell(
            context,
            value: '#$leagueRank',
            label: S.current.league,
          ),
          _buildDivider(),
          _buildStatCell(
            context,
            value: '$badgeCount',
            label: S.current.badges,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
      BuildContext context, {
        required String value,
        required String label,
      }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 0.5,
      height: 36,
      color: Colors.grey.shade200,
    );
  }

  // ── Progress banner với ring SVG ─────────────────────────────
  Widget _buildProgressBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.overall_progress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$unlocked / $total',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.current.achievements_unlocked,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _buildProgressRing(),
        ],
      ),
    );
  }

  Widget _buildProgressRing() {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(54, 54),
            painter: _RingPainter(percent: completionPercent / 100),
          ),
          Text(
            '$completionPercent%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}k';
    }
    return '$xp';
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  const _RingPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const startAngle = -3.14159 / 2; // -90°
    final sweepAngle = 2 * 3.14159 * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent;
}