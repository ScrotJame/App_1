import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/repository/user_repository.dart';

import '../../../cubit/app_cubit.dart';
import '../../../database/app_db.dart';
import '../../../router/app_router.dart';
import '../../../router/router.dart';
import '../../backup/backup_page.dart';

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
    _cubit = ProfileCubit(context.read<UserRepository>());
    _cubit.loadProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }


  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          S.current.base_name, // thêm key này vào l10n nếu chưa có
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: S.current.base_name,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.current.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (_, state) => TextButton(
              onPressed: state.isSaving
                  ? null
                  : () async {
                final ok =
                await _cubit.updateUsername(controller.text);
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: state.isSaving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(S.current.save,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0))),
            ),
          ),
        ],
      ),
    );
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
                  SliverToBoxAdapter(
                      child: _buildHeader(data, state)),
                  SliverToBoxAdapter(
                    child: SizedBox(height: overlap + 8),
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
  Widget _buildHeader(UsersEntrieData data, ProfileState state) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Blue gradient bg
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(50),
                bottomLeft: Radius.circular(50)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF42C8F5), Color(0xFF1E9FD8)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -40, right: -30, child: _bubble(140, 0.09)),
              Positioned(top: 30, left: -20, child: _bubble(100, 0.07)),
              Positioned(bottom: 10, right: 60, child: _bubble(60, 0.06)),
            ],
          ),
        ),

        // Home button
        Positioned(
          top: 50,
          left: -15,
          child: InkWell(
            onTap: () => AppRouter.router.navigateTo(context, Routes.home),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home),
                  const SizedBox(width: 8),
                  const Text(
                    'Home',
                    style: TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Avatar + name + level badge
        Positioned(
          top: 36,
          child: Column(
            children: [
              // ── Avatar với nút edit ──
              GestureDetector(
                onTap: _cubit.pickAndSaveAvatar, // mở thư viện
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ảnh avatar
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: state.isSaving
                        // Hiện shimmer nhẹ khi đang upload
                            ? ColoredBox(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1E9FD8)),
                          ),
                        )
                            : state.avatarPath != null
                            ? Image.file(
                          File(state.avatarPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Image.asset(AppImages.imgAvatar,
                                  fit: BoxFit.cover),
                        )
                            : Image.asset(AppImages.imgAvatar,
                            fit: BoxFit.cover),
                      ),
                    ),

                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SvgPicture.asset(
                            AppImages.icEdit,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Tên + nút edit ──
              Row(
                children: [
                  Text(
                    data.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () => _showEditNameDialog(data.username),
                    child: SvgPicture.asset(
                      AppImages.icEdit,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Level badge
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
                  "${(S.current.level.toUpperCase())}: ${data.level}",
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
        ),
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
  Widget _buildStats(UsersEntrieData data) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF6B35),
            value: data.currentStreak.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.park_rounded,
            iconColor: const Color(0xFFFF8C42),
            value: data.totalLearned.toString(),
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
        height: 1, indent: 54, endIndent: 16, color: Color(0xFFEEEEEE));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).setting,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            children: [
              settingsItem(
                  icon: AppImages.icBackup,
                  label: S.current.save_data,
                  onTap: () {
                    Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const BackupPage()));}),
              divider,
              settingsItem(
                  icon: AppImages.icPrivacy,
                  label: S.current.privacy,
                  onTap: () {}),
              divider,
              settingsItem(
                icon: AppImages.icHelpAndSupport,
                label: S.current.language,
                onTap: () => _showLanguagePicker(context),
              ),
              divider,
              settingsItem(
                  icon: AppImages.icHelpAndSupport,
                  label: S.current.help_support,
                  onTap: () {}),
              divider,
              settingsItem(
                icon: AppImages.icLogOut,
                label: S.current.logout,
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

  void _showLanguagePicker(BuildContext context) {
    final appCubit = context.read<AppCubit>();
    final currentCode = appCubit.state.locale?.languageCode ?? 'en';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              S.current.language,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            ...appCubit.state.supportedLanguages.map((lang) {
              final (code, label) = lang;
              final isSelected = code == currentCode;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected ? const Color(0xFFE3F2FD) : null,
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded,
                    color: Color(0xFF1565C0))
                    : null,
                onTap: () {
                  appCubit.setLanguageCode(code);
                  Navigator.pop(sheetContext);
                },
              );
            }),
          ],
        ),
      ),
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
// SETTINGS ITEM
// ─────────────────────────────────────────────────────────────────
Widget settingsItem({
  required String icon,
  required String label,
  required VoidCallback onTap,
  Color iconColor = const Color(0xFF616161),
  Color labelColor = const Color(0xFF1A1A2E),
  bool showArrow = true,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SvgPicture.asset(icon, color: iconColor, width: 22, height: 22),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFBDBDBD),
                size: 22,
              ),
          ],
        ),
      ),
    ),
  );
}