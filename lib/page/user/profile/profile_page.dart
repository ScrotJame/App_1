import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';

import '../../../router/app_router.dart';
import '../../../router/router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileCubit _cubit;

  static const double headerHeight = 275;
  static const double statsTop = 225;
  static const double statsHeight = 125;
  static const double overlap = statsTop + statsHeight - headerHeight;

  @override
  void initState() {
    super.initState();
    _cubit = ProfileCubit()..loadProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading ||
                state.status == ProfileStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              );
            }

            if (state.status == ProfileStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(state.errorMessage ?? 'Có lỗi xảy ra'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _cubit.refresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final data = state.data!;

            return RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: () async => _cubit.refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(data)),
                  SliverToBoxAdapter(
                    child: SizedBox(height: overlap + 8),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildLearningProgress(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildGardenBadges(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildAccountSettings(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(ProfileData data) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Blue gradient bg
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(50),
              bottomLeft: Radius.circular(50)
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF42C8F5), Color(0xFF1E9FD8)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -40, right: -30, child: _bubble(140, 0.09)),
              Positioned(top: 30,  left: -20,  child: _bubble(100, 0.07)),
              Positioned(bottom: 10, right: 60, child: _bubble(60, 0.06)),
            ],
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
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
                    ),
          ),),
        // Avatar + name + level badge
        Positioned(
          top: 36,
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    data.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Icon(Icons.person,
                          size: 44, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD600).withOpacity(0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  data.level,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: statsTop,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildStats(data),
          ),
        )
      ],
    );
  }

  Widget _bubble(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );

  // ─────────────────────────────────────────────────────────────
  // STATS
  // ─────────────────────────────────────────────────────────────
  Widget _buildStats(ProfileData data) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF6B35),
            value: data.streak.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.park_rounded,
            iconColor: const Color(0xFFFF8C42),
            value: data.totalPoints.toString(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LEARNING PROGRESS
  // ─────────────────────────────────────────────────────────────
  Widget _buildLearningProgress(ProfileData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Learning Progress',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF29B6F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            children: data.courses.asMap().entries.map((e) {
              final isLast = e.key == data.courses.length - 1;
              return Column(
                children: [
                  _CourseItem(course: e.value),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFEEEEEE)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GARDEN BADGES
  // ─────────────────────────────────────────────────────────────
  Widget _buildGardenBadges(ProfileData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Garden Badges',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
              data.badges.map((b) => _BadgeItem(badge: b)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ACCOUNT SETTINGS
  // ─────────────────────────────────────────────────────────────
  Widget _buildAccountSettings() {
    const divider = Divider(
        height: 1,
        indent: 54,
        endIndent: 16,
        color: Color(0xFFEEEEEE));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            children: [
              _SettingsItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () {}),
              divider,
              _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {}),
              divider,
              _SettingsItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacy',
                  onTap: () {}),
              divider,
              _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {}),
              divider,
              _SettingsItem(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                iconColor: const Color(0xFFE53935),
                labelColor: const Color(0xFFE53935),
                showArrow: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER — white card
  // ─────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// COURSE ITEM
// ─────────────────────────────────────────────────────────────────
class _CourseItem extends StatelessWidget {
  final LearningCourse course;

  const _CourseItem({required this.course});

  String _fmt(int n) {
    if (n >= 1000) {
      final d = n / 1000;
      return '${d % 1 == 0 ? d.toInt() : d.toStringAsFixed(1)}k';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Aǎ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  course.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Text(
                '${(course.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: course.progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_fmt(course.current)} / ${_fmt(course.total)} ${course.unit}',
                style:
                const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
              Text(
                '+${course.todayGain} today',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BADGE ITEM
// ─────────────────────────────────────────────────────────────────
class _BadgeItem extends StatelessWidget {
  final BadgeItem badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFF0F0F0),
            border: Border.all(
              color: unlocked
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFCCCCCC),
              width: 2.2,
            ),
          ),
          child: Center(
            child: unlocked
                ? Text(badge.icon,
                style: const TextStyle(fontSize: 26))
                : const Icon(Icons.auto_awesome,
                size: 24, color: Color(0xFFCCCCCC)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: unlocked
                ? const Color(0xFF424242)
                : const Color(0xFFAAAAAA),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SETTINGS ITEM
// ─────────────────────────────────────────────────────────────────
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final bool showArrow;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = const Color(0xFF616161),
    this.labelColor = const Color(0xFF1A1A2E),
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showArrow)
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBDBDBD), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}