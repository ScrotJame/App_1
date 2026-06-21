import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/ultis/error_utils.dart';

import '../../../commons/enums.dart';
import '../../../models/tag_vocab.dart';
import '../learning_cubit.dart';
import '../../../models/quiz_models.dart';

part 'quiz_game_state.dart';

class QuizGameCubit extends Cubit<QuizGameState> {
  final VocabularyRepository _repo;
  final LearningConfig? config;

  final PublishSubject<String> messageController = PublishSubject();

  QuizGameCubit(
    this._repo, {
    this.config,
  }) : super(const QuizGameState());

  // ─── Init ──────────────────────────────────────────

  Future<void> start() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));
    try {
      final words = await _repo.watchAllWordsWithTags().first;

      // Apply filters from config
      var filtered = List<VocabularyWithTags>.from(words);
      if (config != null) {
        if (config!.language != null && config!.language!.isNotEmpty) {
          filtered = filtered
              .where((w) => w.word.language == config!.language)
              .toList();
        }
        if (config!.unitId != null) {
          filtered = filtered
              .where((w) => w.word.unitId == config!.unitId)
              .toList();
        }
      }

      if (filtered.length < 2) {
        emit(state.copyWith(
          loadStatus: LOADSTATUS.FAILED,
          errorMessage: 'Cần ít nhất 2 từ vựng để tạo quiz',
        ));
        return;
      }

      // Shuffle
      final shuffled = List.of(filtered)..shuffle();

      // Limit
      final finalWords =
          (config != null && config!.limitWords != null && config!.limitWords! > 0)
              ? shuffled.take(config!.limitWords!).toList()
              : shuffled;

      // Generate quiz questions from vocabulary
      final questions = _generateQuestions(finalWords, filtered);

      emit(state.copyWith(
        questions: questions,
        currentIndex: 0,
        quizStatus: QuizStatus.inProgress,
        loadStatus: LOADSTATUS.SUCCESS,
        correctCount: 0,
        wrongCount: 0,
        selectedAnswerId: null,
      ));
    } catch (e) {
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: errMsg,
      ));
      messageController.sink.add(errMsg);
    }
  }

  // ─── Question Generation ──────────────────────────

  List<QuizQuestion> _generateQuestions(
    List<VocabularyWithTags> targetWords,
    List<VocabularyWithTags> allWords,
  ) {
    final random = Random();
    final questions = <QuizQuestion>[];

    for (final target in targetWords) {
      // Build wrong options from other words
      final otherWords = allWords
          .where((w) => w.word.id != target.word.id)
          .toList()
        ..shuffle(random);

      final wrongOptions = otherWords.take(3).map((w) {
        return AnswerOption(
          id: 'wrong_${w.word.id}',
          text: w.word.meaning,
          isCorrect: false,
        );
      }).toList();

      final correctOption = AnswerOption(
        id: 'correct_${target.word.id}',
        text: target.word.meaning,
        isCorrect: true,
      );

      // Combine and shuffle
      final allOptions = [...wrongOptions, correctOption]..shuffle(random);

      questions.add(QuizQuestion(
        word: target.word.word,
        pronunciation: target.word.pronunciation,
        imageUrl: null,
        questionText: 'What does this word represent?',
        options: allOptions,
      ));
    }

    return questions;
  }



  // ─── Answer ──────────────────────────────────────────

  void selectAnswer(String answerId) {
    if (state.quizStatus == QuizStatus.answered) return;
    if (state.currentQuestion == null) return;

    final isCorrect = state.currentQuestion!.options
        .any((o) => o.id == answerId && o.isCorrect);

    // Determine battle animation state
    BattleAnimState battleAnim;
    if (isCorrect) {
      final newCorrect = state.correctCount + 1;
      // Enemy defeated khi đúng hết tất cả câu còn lại
      battleAnim = newCorrect >= state.totalQuestions
          ? BattleAnimState.faint
          : BattleAnimState.attack;
    } else {
      battleAnim = BattleAnimState.hurt;
    }

    emit(state.copyWith(
      selectedAnswerId: answerId,
      quizStatus: QuizStatus.answered,
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      wrongCount: isCorrect ? state.wrongCount : state.wrongCount + 1,
      battleAnimState: battleAnim,
    ));

    // Auto next after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!isClosed) nextQuestion();
    });
  }

  // ─── Navigation ──────────────────────────────────────

  void nextQuestion() {
    final next = state.currentIndex + 1;
    if (next >= state.totalQuestions) {
      emit(state.copyWith(
        quizStatus: QuizStatus.completed,
        currentIndex: next,
      ));
    } else {
      emit(state.copyWith(
        currentIndex: next,
        quizStatus: QuizStatus.inProgress,
        selectedAnswerId: null,
        battleAnimState: BattleAnimState.idle,
      ));
    }
  }

  void restart() => start();

  // ─── Lifecycle ──────────────────────────────────────

  @override
  Future<void> close() {
    messageController.close();
    return super.close();
  }
}
