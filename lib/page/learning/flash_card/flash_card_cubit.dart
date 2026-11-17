
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/ultis/error_utils.dart';

import '../../../commons/enums.dart';
import '../../../commons/status_comon.dart';
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

  /// True from a tap on a rating until the next card is shown.
  bool _isRating = false;

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
        // A new session starts its own summary and its own rewards.
        results: const [],
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
    if (_isRating) return;
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

  /// Chuyển sang thẻ tiếp theo mà không chấm. Thẻ bị bỏ qua không được tính
  /// vào kết quả nên không có thưởng.
  void nextCard() {
    if (_isRating) return;
    if (state.status == FlashcardArenaStatus.completed) return;
    _advance();
  }

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

  /// Self-rating of a card. It is recorded as an answer and shown in the
  /// session summary; the word's level only moves in a Test.
  Future<void> rateCard(DifficultyRating rating) async {
    // A second tap during the highlight delay would rate the next card
    // without it ever being shown.
    if (_isRating) return;
    if (state.status == FlashcardArenaStatus.completed) return;
    final card = state.currentCard;
    if (card == null) return;

    _isRating = true;
    try {
      emit(state.copyWith(pendingRating: rating));

      // Wait a brief delay for user feedback visual transitions
      await Future.delayed(const Duration(milliseconds: 350));
      if (isClosed) return;

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

      // "Again" means the word was not recalled.
      await _recordAnswer(card, rating != DifficultyRating.again);
      if (isClosed) return;

      // Slide to the next card
      _advance();
    } finally {
      _isRating = false;
    }
  }

  Future<void> _recordAnswer(VocabularyWithTags card, bool isCorrect) async {
    try {
      await _repoHistory.recordAnswer(
        userKey: userKey,
        wordId: card.word.id,
        wordLevelSnapshot: card.word.level,
        sessionType: SessionType.flashcard,
        isCorrect: isCorrect,
      );
    } catch (_) {
      // Statistics must never interrupt the session.
    }
  }

  @override
  Future<void> close() {
    messageController.close();
    return super.close();
  }
}