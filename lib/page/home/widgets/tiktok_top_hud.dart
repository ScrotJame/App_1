import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/helper/format_helper.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/router/router.dart';

import 'daily_segmented_progress.dart';
import 'gacha_streak_badge.dart';

class TiktokTopHud extends StatelessWidget {
  const TiktokTopHud({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + 4,
        left: 12,
        right: 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gachaGlassBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.gachaGlassBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── 1. Avatar & Level ──
                _buildAvatarSection(context),

                const SizedBox(width: 8),

                // ── 2. Daily Goal Segmented Bar ──
                Expanded(
                  child: Center(
                    child: BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, profileState) {
                        final totalLearned =
                            profileState.data?.totalLearned ?? 0;
                        final completedToday = totalLearned % 10;
                        return DailySegmentedProgress(
                          completed: completedToday == 0 && totalLearned > 0
                              ? 10
                              : completedToday,
                          target: 10,
                          onTap: () {
                            context.push(Routes.learningHistory);
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ── 3. Gems & Streak Flame ──
                _buildGemsAndStreak(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final avatarPath = profileState.avatarPath;
        final hasCustomAvatar =
            avatarPath != null && avatarPath.isNotEmpty && File(avatarPath).existsSync();

        return BlocBuilder<XpCubit, XpState>(
          builder: (context, xpState) {
            final level = xpState.level;
            return GestureDetector(
              onTap: () => context.push(Routes.profile),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gachaGold,
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gachaGold.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasCustomAvatar
                          ? Image.file(
                              File(avatarPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                AppImages.icAvatar,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              AppImages.icAvatar,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gachaGold,
                            AppColors.gachaGoldAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'Lv$level',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGemsAndStreak(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final gems = state.data?.gems ?? 0;
        final streak = state.data?.currentStreak ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gems Badge
            GestureDetector(
              onTap: () => context.push(Routes.shop),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gachaGold.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppImages.imgGem,
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      FormatHelper.formatNumberPrice(gems),
                      style: const TextStyle(
                        color: AppColors.gachaGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Streak Flame Badge
            GachaStreakBadge(
              streak: streak,
              onTap: () => context.push(Routes.streak),
            ),
          ],
        );
      },
    );
  }
}
