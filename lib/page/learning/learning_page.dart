import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../commons/enums.dart';
import '../../repository/vocabulary_repository.dart';
import 'flash_card/flash_card_page.dart';
import 'learning_cubit.dart';
import 'quiz_game/quiz_game_page.dart';
import 'word_matching/word_matching_page.dart';
import 'widgets/learning_config_screen.dart';

// ═══════════════════════════════════════════════════════════════
// ENTRY POINT
// ═══════════════════════════════════════════════════════════════

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  late final LearningCubit _cubit;
  StreamSubscription<String>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _cubit = LearningCubit(context.read<VocabularyRepository>());
    // Lắng nghe side-effect lỗi (PublishSubject) → hiện SnackBar
    _messageSubscription = _cubit.messageController.stream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const _LearningView(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MAIN VIEW — Phase Switch
// ═══════════════════════════════════════════════════════════════

class _LearningView extends StatelessWidget {
  const _LearningView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningCubit, LearningState>(
      // Chỉ rebuild khi phase thay đổi → tránh re-render không cần thiết
      buildWhen: (prev, cur) => prev.phase != cur.phase,
      builder: (context, state) {
        return switch (state.phase) {
          LearningPhase.config    => const LearningConfigScreen(),
          LearningPhase.flashCard => const _FlashCardPhase(),
          LearningPhase.wordMatching => const _WordMatchingPhase(),
          LearningPhase.quizGame => const _QuizGamePhase(),
          LearningPhase.comingSoon => throw UnimplementedError(),
        };
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FLASHCARD PHASE WRAPPER
// ═══════════════════════════════════════════════════════════════

class _FlashCardPhase extends StatelessWidget {
  const _FlashCardPhase();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Khi user nhấn back từ FlashCard → trở về config thay vì pop toàn page
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<LearningCubit>().goToConfig();
        }
      },
      // FlashCardPage tự inject repositories từ context.read() trong initState
      // vì repositories đã được provide từ root app — không cần wrap thêm
      child: const FlashCardPage(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WORD MATCHING PHASE WRAPPER
// ═══════════════════════════════════════════════════════════════

class _WordMatchingPhase extends StatelessWidget {
  const _WordMatchingPhase();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<LearningCubit>().goToConfig();
        }
      },
      child: const WordMatchingPage(),
    );
  }
}

class _ComingSoonPhase extends StatelessWidget {
  const _ComingSoonPhase();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<LearningCubit>().goToConfig();
        }
      },
      child: const SizedBox(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUIZ GAME PHASE WRAPPER
// ═══════════════════════════════════════════════════════════════

class _QuizGamePhase extends StatelessWidget {
  const _QuizGamePhase();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<LearningCubit>().goToConfig();
        }
      },
      child: const QuizGamePage(),
    );
  }
}
