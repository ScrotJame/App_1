import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';

import '../../../commons/app_colors.dart';
import '../../../database/app_db.dart';
import '../../../repository/user_repository.dart';
import '../../../router/app_router.dart';
import '../../../router/router.dart';
import '../test_cubit.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/card_widget.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => ResultScreenState();
}

class ResultScreenState extends State<ResultScreen> {

  // ── Result hero ─────────────────────────────────────────────────────────────

  String _resultEmoji(double percent) {
    if (percent >= 0.9) return '🏆';
    if (percent >= 0.7) return '🎉';
    if (percent >= 0.5) return '📚';
    return '💪';
  }

  String _resultMsg(double percent) {
    if (percent >= 0.9) return 'Xuất sắc!';
    if (percent >= 0.7) return 'Tốt lắm!';
    if (percent >= 0.5) return 'Cố gắng hơn nữa!';
    return 'Ôn tập thêm nhé!';
  }

  Widget _buildResultHero({
    int? correctCount,
    int? total,
    double? percent,
    int? score,
  }) {
    return GradientCard(
      child: Column(
        children: [
          Text(_resultEmoji(percent!), style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(_resultMsg(percent),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Đúng $correctCount/$total câu',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    IconData? icon,
    Color? color,
    String? label,
    String? value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value!,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label!,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Stats row ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow({
    int? correct,
    int? incorrect,
    int? score,
  }) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                icon: Icons.check_circle_rounded,
                color: AppColors.kGreen,
                label: 'Đúng',
                value: '$correct')),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(
                icon: Icons.cancel_rounded,
                color: AppColors.kRed,
                label: 'Sai',
                value: '$incorrect')),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(
                icon: Icons.star_rounded,
                color: AppColors.kAmber,
                label: 'Điểm',
                value: '$score')),
      ],
    );
  }

  // ── Level badge ─────────────────────────────────────────────────────────────

  Widget _buildLevelBadge({int? level, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color!.withOpacity(0.3)),
      ),
      child: Text('Lv.$level',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ── Level up section ────────────────────────────────────────────────────────

  Widget _buildLevelUpSection(List<VocabularyEntry> words) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: AppColors.kGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${words.length} từ được nâng level',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.kGreen),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: words.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, color: AppColors.kBorder, indent: 16),
            itemBuilder: (_, i) {
              final w = words[i];
              final newLevel = w.level;
              final oldLevel = newLevel - 1;
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(w.word,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    _buildLevelBadge(level: oldLevel, color: Colors.grey),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Colors.grey),
                    ),
                    _buildLevelBadge(level: newLevel, color: AppColors.kGreen),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGetRewards(int? xpLabel, int? gemsLabel){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Phần thưởng',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.kGreen),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Image.asset(AppImages.imgGem, width: 16,height: 16,),
                        const SizedBox(width: 4),
                        Text(
                          '$gemsLabel gem',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(width: 38,),
                    Row(
                      children: [
                        Image.asset(AppImages.icStarXp, width: 16,height: 16,),
                        const SizedBox(width: 4),
                        Text(
                          '$xpLabel xp',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kSurface,
      appBar: SimpleAppBar('Kết quả'),
      body: BlocBuilder<TestCubit, TestState>(
        builder: (ctx, s) {
          final c = ctx.read<TestCubit>();
          final pct = s.totalQuestions == 0
              ? 0.0
              : s.correctCount / s.totalQuestions;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultHero(
                  correctCount: s.correctCount,
                  total: s.totalQuestions,
                  percent: pct,
                  score: s.score,
                ),
                const SizedBox(height: 16),

                _buildStatsRow(
                  correct: s.correctCount,
                  incorrect: s.incorrectCount,
                  score: s.score,
                ),
                const SizedBox(height: 20),

                _buildGetRewards(s.xpEarned, s.gemsEarned),
                const SizedBox(height: 20),

                if (s.leveledUpWords.isNotEmpty) ...[
                  _buildLevelUpSection(s.leveledUpWords),
                  const SizedBox(height: 20),
                ],

                buildPrimaryButton(
                  label: 'Làm lại',
                  icon: Icons.replay_rounded,
                  onTap: c.retryTest,
                ),
                const SizedBox(height: 10),
                _buildOutlineButton(
                  label: 'Hoàn thành',
                  icon: Icons.home_outlined,
                  onTap: ()=> AppRouter.router.navigateTo(context, Routes.home),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutlineButton({
    String? label,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label!,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kBlue,
          side: const BorderSide(color: AppColors.kBlue, width: 1.5),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }


}