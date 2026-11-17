import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/page/test_word/screen/result_screen.dart';
import 'package:test_abc/page/test_word/screen/test_screen.dart';
import 'package:test_abc/page/test_word/screen/config_screen.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';

import '../../commons/enums.dart';
import '../daily_quest/daily_quest_cubit.dart';
import '../daily_quest/models/daily_quest_model.dart';
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
      create: (_) => TestCubit(
        context.read<VocabularyRepository>(),
        context.read<LearningHistoryRepository>(),
      ),
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
        // The cubit has already worked out the rewards: only words that
        // levelled up pay out, a repeated test on words that are not due
        // earns nothing.
        final xpCubit = context.read<XpCubit>();
        try {
          context.read<DailyQuestCubit>().onProgressByType(QuestType.completeQuiz);
        } catch (_) {}

        await xpCubit.addXp(state.xpEarned);
        await xpCubit.addGems(state.gemsEarned);
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