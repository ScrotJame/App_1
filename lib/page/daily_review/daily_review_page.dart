import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import 'daily_review_cubit.dart';
import 'screen/empty_screen.dart';
import 'screen/intro_screen.dart';
import 'screen/result_screen.dart';
import 'screen/testing_screen.dart';

class DailyReviewPage extends StatefulWidget {
  const DailyReviewPage({super.key});

  @override
  State<DailyReviewPage> createState() => _DailyReviewPageState();
}

class _DailyReviewPageState extends State<DailyReviewPage> {
  StreamSubscription<String>? _messageSub;

  @override
  void initState() {
    super.initState();
    _messageSub = context
        .read<DailyReviewCubit>()
        .messageController
        .stream
        .listen(_showMessage);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kSurface,
      appBar: _buildAppBar,
      body: SafeArea(
        top: false,
        child: BlocBuilder<DailyReviewCubit, DailyReviewState>(
          buildWhen: (p, c) =>
              p.phase != c.phase || p.loadStatus != c.loadStatus,
          builder: (context, state) {
            if (state.phase == DailyReviewPhase.loading &&
                state.loadStatus == LOADSTATUS.FAILED) {
              return _buildError;
            }
            return switch (state.phase) {
              DailyReviewPhase.loading =>
                const Center(child: CircularProgressIndicator()),
              DailyReviewPhase.empty => const DailyReviewEmptyScreen(),
              DailyReviewPhase.intro => const DailyReviewIntroScreen(),
              DailyReviewPhase.testing => const DailyReviewTestingScreen(),
              DailyReviewPhase.result => const DailyReviewResultScreen(),
            };
          },
        ),
      ),
    );
  }

  PreferredSizeWidget get _buildAppBar => AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          S.of(context).daily_review_title,
          style: const TextStyle(
            color: AppColors.textBlack,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );

  Widget get _buildError => Center(
        child: TextButton.icon(
          onPressed: () => context.read<DailyReviewCubit>().load(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(S.of(context).retry),
        ),
      );
}
