import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/achievement/widgets/achievement_badge_row_widget.dart';
import 'package:test_abc/page/achievement/widgets/achievement_card_widget.dart';
import 'package:test_abc/page/achievement/widgets/achievement_filter_bar_widget.dart';
import 'package:test_abc/page/achievement/widgets/achievement_summary_widget.dart';
import 'package:test_abc/page/achievement/widgets/achievement_unlock_dialog.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/page/widgets/app_gradient_header.dart';
import 'package:test_abc/repository/achievement_repository.dart';

import '../../generated/l10n.dart';
import '../../models/entity/achivement_entity.dart';
import '../../router/app_router.dart';
import '../../router/router.dart';
import 'achievement_cubit.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {

  late final AchievementCubit _cubit;
  late StreamSubscription _messageSub;
  late StreamSubscription _unlockSub;

  @override
  void initState() {
    super.initState();
    _cubit = AchievementCubit(context.read<AchievementRepository>());
    final user = context.read<ProfileCubit>().state.data;

    _cubit.setUser(user);
    _cubit.initData(UserSession.instance.userKey);

    // Lắng nghe thông báo lỗi
    _messageSub = _cubit.messageController.listen((msg) {
      _showErrorSnackbar(msg);
    });

    // Lắng nghe mở khóa thành tựu mới
    _unlockSub = _cubit.newUnlockController.listen((unlocked) {
      _showUnlockDialog(unlocked);
    });
  }

  @override
  void dispose() {
    _cubit.close();
    _messageSub.cancel();
    _unlockSub.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: BlocBuilder<AchievementCubit, AchievementState>(
        builder: (context, state) {

          final data = state.user;
          if (data == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
              onRefresh: () async{
                await Future.wait(
                    [_cubit.initData(UserSession.instance.userKey),]
                );
                },
              child: Column(
                children: [
                  _buildHeader(data),
                  Expanded(child:_buildBody(context)),
                ],
              )
          );
          },
      ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────
  Widget _buildHeader(UsersEntrieData user){
    return BlocBuilder<AchievementCubit, AchievementState>(
      buildWhen: (prev, curr) => false,
      builder: (context, state){
        final topPadding = MediaQuery.of(context).padding.top;
        return AppGradientHeader(
          height: topPadding + 90,
          gradientColors: const [Color(0xFF7B8FE0), Color(0xFF5B6EC7)],
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  IconButton(
                    icon: Icon( Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                        AppRouter.router.navigateTo(context, Routes.home);
                    },
                  ),
                Text(
                  S.current.hall_of_fame,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 14, color: Color(0xFFE65100)),
                      const SizedBox(width: 3),
                      Text(
                        user.longestStreak.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  // ── Body ──────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    return BlocBuilder<AchievementCubit, AchievementState>(
      buildWhen: (prev, curr) => prev.loadStatus != curr.loadStatus,
      builder: (context, state) {
        if (state.loadStatus == LOADSTATUS.LOADING) return _buildLoadingWidget;
        if (state.loadStatus == LOADSTATUS.FAILED) return _buildFailureWidget;
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Stats + Progress banner ───────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: BlocBuilder<AchievementCubit, AchievementState>(
              buildWhen: (prev, curr) =>
              prev.unlockedCount != curr.unlockedCount ||
                  prev.totalVisible != curr.totalVisible,
              builder: (context, state) => AchievementSummaryWidget(
                unlocked: state.unlockedCount,
                total: state.totalVisible,
                completionPercent: state.completionPercent,
                totalXp: 12400,
                leagueRank: 4,
                badgeCount: state.unlockedCount,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Section title ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              S.current.earned_achievements,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Filter chips ──────────────────────────────────────
        SliverToBoxAdapter(
          child: BlocBuilder<AchievementCubit, AchievementState>(
            buildWhen: (prev, curr) =>
            prev.selectedCategory != curr.selectedCategory,
            builder: (context, state) => AchievementFilterBarWidget(
              selected: state.selectedCategory,
              onSelect: (cat) =>
                  context.read<AchievementCubit>().onFilterCategory(cat),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Achievement list ──────────────────────────────────
        BlocBuilder<AchievementCubit, AchievementState>(
          buildWhen: (prev, curr) =>
          prev.filteredAchievements != curr.filteredAchievements,
          builder: (_, state) {
            final items = state.filteredAchievements;
            if (items.isEmpty) {
              return SliverToBoxAdapter(child: _buildEmptyWidget);
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AchievementCardWidget(achievement: items[i]),
                  ),
                  childCount: items.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ── Loading ───────────────────────────────────────────────────
  Widget get _buildLoadingWidget => const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 80),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  // ── Failure ───────────────────────────────────────────────────
  Widget get _buildFailureWidget => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined,
              size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            S.current.load_failed,
            style:
            const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                context.read<AchievementCubit>().initData(UserSession.instance.userKey),
            child: Text(S.current.retry),
          ),
        ],
      ),
    ),
  );

  // ── Empty state ───────────────────────────────────────────────
  Widget get _buildEmptyWidget => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Text(
        S.current.no_achievements,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────
  void _showUnlockDialog(List<AchivementEntity> unlocked) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AchievementUnlockDialog(achievements: unlocked),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
    // Thay bằng Flushbar nếu dự án dùng another_flushbar
  }

  void _onViewAllBadges() {
    // Navigate to badges page nếu cần
  }
}