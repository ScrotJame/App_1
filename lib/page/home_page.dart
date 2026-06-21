import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/components/bager_widget.dart';
import 'package:test_abc/page/streak/streak_page.dart';
import 'package:test_abc/page/training_feed/training_feed_page.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/page/widgets/app_bar_custom.dart';

import '../commons/app_images.dart';
import '../helper/format_helper.dart';
import '../router/app_router.dart';
import '../router/router.dart';
import 'widgets/avatar/avatar_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBarCustom(
        showBack: false,
        topActions: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              return XpBarWidget(
                avatarUrl: profileState.avatarPath ?? AppImages.icAvatar,
                onTap: () {
                  AppRouter.router.navigateTo(context, Routes.profile);
                },
              );
            },
          ),
          _smallIcon()
        ],
      ),
      body: const TrainingFeedPage(isEmbedInHome: true),
    );
  }

  Widget _smallIcon() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (BuildContext context, ProfileState state) {
        final gems = state.data?.gems ?? 0;
        final streak = state.data?.currentStreak ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBarAction(
              icon: AppImages.imgGem,
              label: FormatHelper.formatNumberPrice(gems),
            ),
            const SizedBox(width: 8),
            AppBarAction(
              icon: AppImages.icFire,
              label: streak.toString(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StreakPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
