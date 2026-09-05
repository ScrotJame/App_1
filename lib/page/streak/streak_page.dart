import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_abc/commons/app_images.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import '../../generated/l10n.dart';
import '../../repository/user_repository.dart';
import '../../router/router.dart';
import '../../ultis/extension/label_extension.dart';
import '../daily_quest/widgets/daily_quest_card.dart';
import '../widgets/buble_stack.dart';
import 'streak_cubit.dart';

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage>
    with SingleTickerProviderStateMixin {
  late final StreakCubit _cubit;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;
  StreamSubscription<String>? _messageSub;

  static const double headerHeight = 310;

  @override
  void initState() {
    super.initState();
    _cubit = StreakCubit(context.read<UserRepository>());
    _messageSub = _cubit.messageController.stream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _cubit.loadProfile();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _cubit.close();
    _animController.dispose();
    super.dispose();
  }

  String _dayLabel(int index) {
    switch (index) {
      case 0: return S.of(context).mon;
      case 1: return S.of(context).tue;
      case 2: return S.of(context).wed;
      case 3: return S.of(context).thu;
      case 4: return S.of(context).fri;
      case 5: return S.of(context).sat;
      case 6: return S.of(context).sun;
      default: return '';
    }
  }

  String _weekTitle(
      BuildContext context,
      List<DayStreak> days,
      int weekOffset,
      ) {
    if (days.isEmpty) return '';

    if (weekOffset == 0) {
      return S.of(context).this_week.capitalizeWords();
    }

    if (weekOffset == -1) {
      return S.of(context).last_week.capitalizeWords();
    }

    final first = days.first;
    final last = days.last;

    final firstMonth = _monthAbbr(context, first.month);
    final lastMonth = _monthAbbr(context, last.month);

    if (first.month == last.month) {
      return '$firstMonth ${first.date}–${last.date}, ${first.year}';
    }

    return '$firstMonth ${first.date} – $lastMonth ${last.date}';
  }

  String _monthAbbr(BuildContext context, int month) {
    switch (month) {
      case 1:  return S.of(context).jan.capitalizeWords();
      case 2:  return S.of(context).feb.capitalizeWords();
      case 3:  return S.of(context).mar.capitalizeWords();
      case 4:  return S.of(context).apr.capitalizeWords();
      case 5:  return S.of(context).may.capitalizeWords();
      case 6:  return S.of(context).jun.capitalizeWords();
      case 7:  return S.of(context).jul.capitalizeWords();
      case 8:  return S.of(context).aug.capitalizeWords();
      case 9:  return S.of(context).sep.capitalizeWords();
      case 10: return S.of(context).oct.capitalizeWords();
      case 11: return S.of(context).nov.capitalizeWords();
      case 12: return S.of(context).dec.capitalizeWords();
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F5),
        body: BlocBuilder<StreakCubit, StreakState>(
          builder: (context, state) {
            if (state.loadStatus == LOADSTATUS.LOADING) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35), strokeWidth: 2.5),
              );
            }
            if (state.loadStatus == LOADSTATUS.FAILED) {
              return Center(
                child: Text(state.errorMessage ?? 'Có lỗi xảy ra',
                    style: GoogleFonts.balooBhai2(color: Colors.red)),
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          // ─── Header ──────────────────────────────
                          Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: headerHeight,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(50),
                                    bottomLeft: Radius.circular(50),
                                  ),
                                  gradient: AppColors.streakGradient,
                                ),
                                child: const BubbleBackground(),
                              ),
                              Positioned(
                                top: 20,
                                child: Column(
                                  children: [
                                    ScaleTransition(
                                      scale: _scaleAnim,
                                      child: _buildFlameSection(state),
                                    ),
                                    const SizedBox(height: 26),
                                    Text(
                                      S.of(context).day_streak,
                                      style: GoogleFonts.balooBhai2(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1A1A1A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'You are doing really great, ${state.data?.username}!',
                                      style: GoogleFonts.balooBhai2(
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (state.streakWasReset) _buildResetBanner(),

                          if (state.longestStreak > 0)
                            _buildStreakInfoRow(state),

                          const SizedBox(height: 8),

                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildWeekSection(state),
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                            child: const DailyQuestCard(),
                          ),

                          const SizedBox(height: 20),

                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildStatsCard(state),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Home button ──────────────────────────────────
                Positioned(
                  top: 50,
                  left: -15,
                  child: InkWell(
                    onTap: () =>
                        context.go(Routes.home),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home),
                          const SizedBox(width: 8),
                          Text(S.of(context).home.capitalizeWords(),
                              style: GoogleFonts.balooBhai2()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Streak reset banner ──────────────────────────────────────────
  Widget _buildResetBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD4BC), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF6B35), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your streak was reset — you missed a day. Start fresh today! 🔥',
                style: GoogleFonts.balooBhai2(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF6B35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakInfoRow(StreakState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: _buildInfoChip(
        icon: Icons.emoji_events_rounded,
        label: 'Best: ${state.longestStreak} days',
        color: const Color(0xFFFFC107),
      ),
    );
  }

  Widget _buildInfoChip(
      {required IconData icon,
        required String label,
        required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.balooBhai2(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  // ─── Flame + number ───────────────────────────────────────────────
  Widget _buildFlameSection(StreakState state) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.12),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          Image.asset(AppImages.icFire2, width: 100, height: 100),
          Positioned(
            bottom: -65,
            child: Text(
              '${state.weekStreak}',
              style: GoogleFonts.balooBhai2(
                  fontSize: 100, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Week section ─────────────────────────────────────────────────
  Widget _buildWeekSection(StreakState state) {
    final title = _weekTitle(
      context,
      state.weekDays,
      state.weekOffset,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left_rounded,
              onTap: _cubit.previousWeek,
            ),
            GestureDetector(
              onTap: state.weekOffset != 0 ? _cubit.goToCurrentWeek : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.balooBhai2(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: state.weekOffset == 0
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFFF6B35),
                    ),
                  ),
                  if (state.weekOffset != 0) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: Color(0xFFFF6B35),
                    ),
                  ],
                ],
              ),
            ),
            _buildNavButton(
              icon: Icons.chevron_right_rounded,
              onTap: state.canGoNext ? _cubit.nextWeek : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWeekRow(state),
      ],
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withOpacity(0.4),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]
              : null,
        ),
        child: Icon(icon,
            size: 20,
            color: enabled
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFCCCCCC)),
      ),
    );
  }

  Widget _buildWeekRow(StreakState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: state.weekDays.map(_buildDayItem).toList(),
      ),
    );
  }

  Widget _buildDayItem(DayStreak day) {
    return Column(
      children: [
        Text(
          _dayLabel(day.weekdayIndex), // ✅ resolve tại đây, luôn đúng ngôn ngữ
          style: GoogleFonts.balooBhai2(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: day.isToday
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFAAAAAA),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text('${day.date}',
            style: GoogleFonts.balooBhai2(
              fontSize: 10,
              color: day.isFuture
                  ? const Color(0xFFDDDDDD)
                  : day.isToday
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFFAAAAAA),
            )),
        const SizedBox(height: 4),
        if (day.isCompleted)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.streakGradient,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 18),
          )
        else
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day.isToday
                  ? const Color(0xFFFF6B35).withOpacity(0.08)
                  : const Color(0xFFF5F5F5),
              border: day.isToday
                  ? Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  width: 1.5)
                  : null,
            ),
            child: day.isFuture
                ? null
                : Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.isToday
                      ? const Color(0xFFFF6B35).withOpacity(0.5)
                      : const Color(0xFFDDDDDD),
                ),
              ),
            ),
          ),
      ],
    );
  }


  // ─── Stats card ───────────────────────────────────────────────────
  Widget _buildStatsCard(StreakState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Column(
        children: [
          Text(S.of(context).your_stats.capitalizeWords(),
              style: GoogleFonts.balooBhai2(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _buildStatItem('Current', '${state.weekStreak}',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFFF6B35)),
                      _buildDivider(),
                      _buildStatItem('Best', '${state.longestStreak}',
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFFFFC107)),
                      _buildDivider(),
                      _buildStatItem(
                          'Word Learn', '${state.data?.totalLearned}'),
                      _buildDivider(),
                      _buildStatItem('Minutes', '${state.stats.minutes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (state.stats.insightsAvailable > 0)
                  GestureDetector(
                    onTap: _cubit.onInsightsTapped,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFFFFD4BC), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 15, color: Color(0xFFFF6B35)),
                          const SizedBox(width: 6),
                          Text(
                              '${state.stats.insightsAvailable} Insights Available',
                              style: GoogleFonts.balooBhai2(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFF6B35))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Expanded(
      child: Column(
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: iconColor ?? const Color(0xFFAAAAAA))
          else
            const SizedBox(height: 16),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.balooBhai2(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFAAAAAA),
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.balooBhai2(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -1)),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, color: const Color(0xFFEEEEEE));
}