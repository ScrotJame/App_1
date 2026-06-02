import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/service/sm2/sm2_algorithm.dart';
import 'package:test_abc/ultis/error_utils.dart';

import '../../../commons/enums.dart';
import '../../../commons/user_sesion.dart';
import '../../../models/entity/active_companion_entity.dart';
import '../../../models/flash_card_model.dart';
import '../../../models/tag_vocab.dart';
import '../learning_cubit.dart';
part 'flash_card_state.dart';

class FlashCardCubit extends Cubit<FlashCardState> {
  final VocabularyRepository _repo;
  final CompanionRepository _repoCompanion;
  final LearningHistoryRepository _repoHistory;
  final LearningConfig? config;

  final PublishSubject<String> messageController = PublishSubject();

  FlashCardCubit(
    this._repo,
    this._repoCompanion,
    this._repoHistory, {
    this.config,
  }) : super(FlashCardState());

  final userKey = UserSession.instance.userKey;

  Future<void> start() async {
    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));
    try {
      final words = await _repo.watchAllWordsWithTags().first;
      
      // Apply filters from config
      var filtered = List<VocabularyWithTags>.from(words);
      if (config != null) {
        if (config!.language != null && config!.language!.isNotEmpty) {
          filtered = filtered.where((w) => w.word.language == config!.language).toList();
        }
        if (config!.unitId != null) {
          filtered = filtered.where((w) => w.word.unitId == config!.unitId).toList();
        }
      }

      // Shuffle
      final shuffled = List.of(filtered)..shuffle();

      // Limit the number of words
      final finalWords = (config != null && config!.limitWords != null && config!.limitWords! > 0)
          ? shuffled.take(config!.limitWords!).toList()
          : shuffled;

      emit(state.copyWith(
        cards: finalWords,
        currentIndex: 0,
        isFlipped: false,
        status: finalWords.isEmpty
            ? FlashcardArenaStatus.completed
            : FlashcardArenaStatus.inProgress,
        loadstatus: LOADSTATUS.SUCCESS,
        clearPending: true,
      ));
    } catch (e) {
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: errMsg,
      ));
      messageController.sink.add(errMsg);
    }
  }

  /// Lật / lật lại card hiện tại
  void flipCard() {
    if (state.status == FlashcardArenaStatus.completed) return;
    final flipped = !state.isFlipped;
    emit(state.copyWith(
      isFlipped: flipped,
      status: flipped
          ? FlashcardArenaStatus.flipped
          : FlashcardArenaStatus.inProgress,
      clearPending: true,
    ));
  }

  Future<void> exitAndSave(double wordsCount) async {
    if (!state.hasActiveCompanion || wordsCount <= 0) return;
    try {
      final foodEarned = await _repoCompanion.earnFood(
        userKey: userKey,
        wordsLearned: wordsCount,
      );
      if (foodEarned > 0) {
        emit(state.copyWith(lastFoodEarned: foodEarned));
      }
    } catch (e) {
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      emit(state.copyWith(
        companionStatus: LOADSTATUS.FAILED,
      ));
      messageController.sink.add(errMsg);
    }
  }


  void restart() => start();

  // ── Navigation ──────────────────────────────

  /// Chuyển sang thẻ tiếp theo
  void nextCard() => _advance();

  // ── Private ─────────────────────────────────

  void _advance() {
    final next = state.currentIndex + 1;
    if (next >= state.totalCards) {
      emit(state.copyWith(
        status: FlashcardArenaStatus.completed,
        currentIndex: next,
        clearPending: true,
      ));
    } else {
      emit(state.copyWith(
        status: FlashcardArenaStatus.inProgress,
        currentIndex: next,
        isFlipped: false,
        clearPending: true,
      ));
    }
  }


  Future<void> earnFood(double wordsCount) async {
    if (!state.hasActiveCompanion || wordsCount <= 0) return;

    try {
      final foodEarned = await _repoCompanion.earnFood(
        userKey: userKey,
        wordsLearned: wordsCount,
      );

      if (foodEarned > 0) {
        emit(state.copyWith(lastFoodEarned: foodEarned));
      }
    } catch (e) {
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      emit(state.copyWith(
        companionStatus: LOADSTATUS.FAILED,
      ));
      messageController.sink.add(errMsg);
    }
  }

  /// Rate difficulty of recall using SM-2
  Future<void> rateCard(DifficultyRating rating) async {
    final card = state.currentCard;
    if (card == null) return;

    emit(state.copyWith(pendingRating: rating));

    // Wait a brief delay for user feedback visual transitions
    await Future.delayed(const Duration(milliseconds: 350));

    try {
      // Retrieve previous SM-2 values (or use Drift default values if newly created)
      final int prevRep = card.word.repetitions;
      final int prevInt = card.word.interval;
      final double prevEF = card.word.easeFactor;

      // Calculate new parameters using SM-2 spaced repetition algorithm
      final sm2 = SM2Algorithm.calculate(
        rating: rating,
        prevRepetitions: prevRep,
        prevInterval: prevInt,
        prevEaseFactor: prevEF,
      );

      // Save calculations to Drift Database
      await _repo.updateWordSM2Progress(
        wordId: card.word.id,
        easeFactor: sm2.easeFactor,
        repetitions: sm2.repetitions,
        interval: sm2.interval,
        nextReview: sm2.nextReview,
      );

      // Save study history log to Drift database
      final isCorrect = rating != DifficultyRating.again;
      await _repoHistory.logWordLearned(
        userKey: userKey,
        wordId: card.word.id,
        wordLevelSnapshot: sm2.repetitions,
        sessionType: 'Flashcard',
        isCorrect: isCorrect,
      );

      // Save local session results for display
      final cardModel = FlashcardModel(
        id: card.word.id.toString(),
        category: 'Vocab',
        frontText: card.word.word,
        pronunciation: card.word.pronunciation ?? '',
        backText: card.word.meaning,
        backDescription: card.word.example ?? '',
      );

      final updatedResults = List<FlashcardResult>.from(state.results)
        ..add(FlashcardResult(card: cardModel, rating: rating));

      emit(state.copyWith(
        results: updatedResults,
      ));
    } catch (e) {
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      messageController.sink.add(errMsg);
    }

    // Slide to the next card
    _advance();
  }

  @override
  Future<void> close() {
    messageController.close();
    return super.close();
  }
}