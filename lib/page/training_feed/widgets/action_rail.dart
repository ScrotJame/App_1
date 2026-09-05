import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/page/training_feed/widgets/rail_button_widget.dart';

import '../../../commons/app_colors.dart';
import '../training_feed_cubit.dart';

class ActionRail extends StatelessWidget {
  const ActionRail({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrainingFeedCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RailButton(
          icon: Icons.favorite_rounded,
          label: 'Đã thuộc',
          isActive: false,
          activeColor: AppColors.xoayMagenta,
          onTap: cubit.markCurrentCardAsLearned,
        ),
        const SizedBox(height: 18),
        RailButton(
          icon: Icons.bookmark_rounded,
          label: 'Ôn lại',
          isActive: false,
          activeColor: AppColors.xoayGold,
          onTap: cubit.saveCurrentCardForReview,
        ),
        const SizedBox(height: 18),
        RailButton(
          icon: Icons.volume_up_rounded,
          label: 'Phát âm',
          isActive: false,
          activeColor: AppColors.xoayCyan,
          onTap: cubit.pronounceCurrentWord,
        ),
      ],
    );
  }
}