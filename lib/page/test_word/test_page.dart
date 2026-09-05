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
        final int totalGems = state.leveledUpWords.fold(0, (sum, entry) {
          return sum + state.gemsForLevel(entry.level);
        });
        final int totalXp = state.leveledUpWords.fold(0, (sum, entry) {
          return sum + state.gemsForLevel(entry.level);
        });

        final int gemsEarned = totalGems > 0 ? totalGems : state.score * 10;
        final int xpEarned = totalXp > 0 ? (totalXp / 2).toInt() : (state.score / 2).toInt();
        context.read<TestCubit>().setRewards(xpEarned: xpEarned, gemsEarned: gemsEarned);

        await context.read<XpCubit>().addXp(xpEarned);
        await context.read<XpCubit>().addGems(gemsEarned);

        try {
          context.read<DailyQuestCubit>().onProgressByType(QuestType.completeQuiz);
        } catch (_) {}
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