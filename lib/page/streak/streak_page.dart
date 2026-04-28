import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_abc/commons/app_images.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import '../../router/app_router.dart';
import '../../router/router.dart';
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

  static const double headerHeight = 275;
  static const double statsTop = 225;
  static const double statsHeight = 125;
  static const double overlap = statsTop + statsHeight - headerHeight;

  @override
  void initState() {
    super.initState();
    _cubit = StreakCubit()..loadStreak();

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
    _cubit.close();
    _animController.dispose();
    super.dispose();
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
                  color: Color(0xFFFF6B35),
                  strokeWidth: 2.5,
                ),
              );
            }

            if (state.loadStatus == LOADSTATUS.FAILED) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Có lỗi xảy ra',
                  style: GoogleFonts.balooBhai2(color: Colors.red),
                ),
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
                        // ─── Flame + Streak number ───────────────
                        Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: headerHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
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
                                    'Week Streak',
                                    style: GoogleFonts.balooBhai2(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),


                        const SizedBox(height: 6),
                        Text(
                          'You are doing really great, ${state.userName}!',
                          style: GoogleFonts.balooBhai2(
                            fontSize: 14
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ─── Week days ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildWeekRow(state),
                        ),
                        const SizedBox(height: 28),

                        // ─── Stats card ──────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildStatsCard(state),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

                Positioned(
                  top:50,
                  left: -15,
                  child: InkWell(
                    onTap: (){AppRouter.router.navigateTo(context, Routes.home);},
                    child: Container(
                      padding:const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home),
                          const SizedBox(width: 8,),
                          Text(
                            'Home',
                            style:  GoogleFonts.balooBhai2(),
                          ),
                        ],
                      ),
                    ),
                  ),),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Flame icon + streak number ───────────────────────────────────
  Widget _buildFlameSection(StreakState state) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Circle background
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

          // Flame image (center chuẩn)
          Image.asset(
            AppImages.icFire2,
            width: 100,
            height: 100,
          ),

          // Number
          Positioned(
            bottom: -65,
            child: Text(
              '${state.weekStreak}',
              style: GoogleFonts.balooBhai2(
                fontSize: 100,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Week row M T W T F S S ──────────────────────────────────────
  Widget _buildWeekRow(StreakState state) {
    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: state.weekDays
            .map((day) => _buildDayItem(day))
            .toList(),
      ),
    );
  }

  Widget _buildDayItem(DayStreak day) {
    return Column(
      children: [
        // Label
        Text(
          day.label,
          style: GoogleFonts.balooBhai2(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: day.isToday
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFAAAAAA),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Circle / date
        if (day.isCompleted)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.streakGradient,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          )
        else
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                '${day.date ?? ''}',
                style: GoogleFonts.balooBhai2(
                  fontSize: 16,
                  fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
                  color: day.isToday
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFBBBBBB),
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Column(
        children: [
          // Title
          Text(
            'Your Stats',
            style: GoogleFonts.balooBhai2(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _buildStatItem('Days', '${state.stats.days}'),
                      _buildDivider(),
                      _buildStatItem('Lessons', '${state.stats.lessons}'),
                      _buildDivider(),
                      _buildStatItem('Quizzes', '${state.stats.quizzes}'),
                      _buildDivider(),
                      _buildStatItem('Minutes', '${state.stats.minutes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Insights button
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
                          color: const Color(0xFFFFD4BC),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: Color(0xFFFF6B35),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${state.stats.insightsAvailable} Insights Available',
                            style: GoogleFonts.balooBhai2(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
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

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.balooBhai2(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFAAAAAA),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.balooBhai2(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      color: const Color(0xFFEEEEEE),
    );
  }
}
