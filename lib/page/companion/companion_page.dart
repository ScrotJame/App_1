import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/page/companion/screen/browsing_screen.dart';
import 'package:test_abc/page/companion/screen/choice_screen.dart';
import 'package:test_abc/page/companion/screen/companion_dialogs.dart';
import 'package:test_abc/page/companion/screen/loading_error_screen.dart';
import 'package:test_abc/page/companion/screen/main_screen.dart';
import 'package:test_abc/ultis/extension/label_extension.dart';
import '../../generated/l10n.dart';
import '../../repository/companion_repository.dart';
import '../widgets/app_gradient_header.dart';
import '../widgets/bubble_button.dart';
import 'companion_cubit.dart';

const kThemeColors = [Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF2E7D32)];
const kGreenAccent = Color(0xFF388E3C);
const kSurface = Colors.white;

class CompanionPage extends StatefulWidget {
  final String userKey;
  const CompanionPage({super.key, required this.userKey});

  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> with TickerProviderStateMixin {
  late CompanionCubit _cubit;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _cubit = CompanionCubit(
      repository: context.read<CompanionRepository>(),
      userKey: widget.userKey,
    );

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, CompanionState state) {
    if (state.justReachedLevel != null) {
      showLevelUpDialog(context, state.justReachedLevel!);
      _cubit.clearFeedback();
    }
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cubit.clearFeedback();
    }
    if (state.status == CompanionStatus.confirmingDelete) {
      showDeleteDialog(context, state, _cubit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<CompanionCubit, CompanionState>(
        listenWhen: (p, c) =>
        c.justReachedLevel != null ||
            c.errorMessage != null ||
            c.status == CompanionStatus.confirmingDelete,
        listener: _onStateChanged,
        child: Scaffold(
          body: BlocBuilder<CompanionCubit, CompanionState>(
            buildWhen: (p, c) => p.status != c.status,
            builder: (context, statusState) {
              final isActive = statusState.status == CompanionStatus.active ||
                  statusState.status == CompanionStatus.confirmingDelete;
              return Container(
                decoration: isActive
                    ? const BoxDecoration(color: Color(0xFFF0FAF0))
                    : const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: kThemeColors,
                    stops: [0, 0.5, 1],
                  ),
                ),
                child: BlocBuilder<CompanionCubit, CompanionState>(
                  builder: (context, state) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _routeBody(context, state),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _routeBody(BuildContext context, CompanionState state) {
    switch (state.status) {
      case CompanionStatus.initial:
      case CompanionStatus.loading:
        return const CompanionLoadingScreen();
      case CompanionStatus.awaitingChoice:
        return CompanionTypeChoiceScreen(cubit: _cubit);
      case CompanionStatus.browsing:
        return CompanionBrowsingScreen(cubit: _cubit, state: state);
      case CompanionStatus.active:
      case CompanionStatus.confirmingDelete:
        return CompanionActiveView(cubit: _cubit, state: state, bounceAnim: _bounceAnim);
      case CompanionStatus.error:
        return CompanionErrorScreen(cubit: _cubit, message: state.errorMessage);
    }
  }
}