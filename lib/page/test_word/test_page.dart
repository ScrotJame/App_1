import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/page/test_word/screen/result_screen.dart';
import 'package:test_abc/page/test_word/screen/test_screen.dart';
import 'package:test_abc/page/test_word/widgets/app_bar_widget.dart';
import 'package:test_abc/page/test_word/widgets/button_widget.dart';
import 'package:test_abc/page/test_word/widgets/card_widget.dart';
import 'package:test_abc/page/test_word/screen/config_screen.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import '../../database/app_db.dart';
import '../test_word/test_cubit.dart';
import '../widgets/avatar/xp_cubit.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// ══════════════════════════════════════════════════════════════════════════════

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TestCubit(context.read<VocabularyRepository>()),
      child: const _TestView(),
    );
  }
}

class _TestView extends StatelessWidget {
  const _TestView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TestCubit, TestState>(
      listenWhen: (p, c) => p.phase != c.phase && c.phase == TestPhase.result,
      listener: (context, state) async {
        final double xpTest = state.score / 2;
        await context.read<XpCubit>().addXp(xpTest.toInt());
      },
      buildWhen: (p, c) => p.phase != c.phase,
      builder: (_, s) => switch (s.phase) {
        TestPhase.config  => const ConfigScreen(),
        TestPhase.testing => const TestingScreen(),
        TestPhase.result  => const ResultScreen(),
      },
    );
  }
}
