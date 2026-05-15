import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../../../commons/enums.dart';
import '../../../commons/user_sesion.dart';
import '../../../models/entity/active_companion_entity.dart';
import '../../../models/flash_card_model.dart';
import '../../../models/tag_vocab.dart';
part 'flash_card_state.dart';

class FlashCardCubit extends Cubit<FlashCardState> {
  final VocabularyRepository _repo;
  final CompanionRepository _repoCompanion;

  FlashCardCubit(this._repo, this._repoCompanion) : super(FlashCardState());

  final userKey = UserSession.instance.userKey;

  Future<void> start() async {
    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));
    try {
      final words = await _repo.watchAllWordsWithTags().first;
      // Shuffle để mỗi session thứ tự khác nhau
      final shuffled = List.of(words)..shuffle();
      emit(state.copyWith(
        cards: shuffled,
        currentIndex: 0,
        isFlipped: false,
        status: shuffled.isEmpty
            ? FlashcardArenaStatus.completed
            : FlashcardArenaStatus.inProgress,
        loadstatus: LOADSTATUS.SUCCESS,
        clearPending: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
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
      emit(state.copyWith(
        companionStatus: LOADSTATUS.FAILED,
        errorMessage: e.toString(),
      ));
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
      emit(state.copyWith(
        companionStatus: LOADSTATUS.FAILED,
        errorMessage: e.toString(),
      ));
    }
  }

}