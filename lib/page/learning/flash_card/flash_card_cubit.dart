import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../commons/enums.dart';
import '../../../models/flash_card_model.dart';

part 'flash_card_state.dart';

class FlashCardCubit extends Cubit<FlashCardState> {
  FlashCardCubit() : super(FlashCardState());

  void start() {
    emit(FlashCardState(
      status: FlashcardArenaStatus.inProgress,
      cards: List<FlashcardModel>.from(FlashcardMockData.cards),
    ));
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
  void rate(DifficultyRating rating) {
    if (state.currentCard == null) return;
    if (state.status == FlashcardArenaStatus.completed) return;

    final newResults = [...state.results, FlashcardResult(card: state.currentCard!, rating: rating)];

    // 1. Highlight rating button
    emit(state.copyWith(pendingRating: rating, results: newResults));

    // 2. Advance sau animation delay
    Future.delayed(const Duration(milliseconds: 350), _advance);
  }

  void restart() => start();

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
