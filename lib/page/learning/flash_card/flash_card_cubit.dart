import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../../../commons/enums.dart';
import '../../../models/flash_card_model.dart';
import '../../../models/tag_vocab.dart';
part 'flash_card_state.dart';

class FlashCardCubit extends Cubit<FlashCardState> {
  final VocabularyRepository _repo;

  FlashCardCubit(this._repo) : super(FlashCardState());

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

  /// Chọn độ khó → highlight → advance sau 350ms
  // void rate(DifficultyRating rating) {
  //   if (state.currentCard == null) return;
  //   if (state.status == FlashcardArenaStatus.completed) return;
  //
  //   final newResults = [...state.results, FlashcardResult(card: state.currentCard, rating: rating)];
  //
  //   // 1. Highlight rating button
  //   emit(state.copyWith(pendingRating: rating, results: newResults));
  //
  //   // 2. Advance sau animation delay
  //   Future.delayed(const Duration(milliseconds: 350), _advance);
  // }

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
}