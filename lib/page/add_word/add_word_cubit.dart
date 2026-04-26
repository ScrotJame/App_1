import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';

import '../../commons/enums.dart';
import '../../repository/vocabulary_repository.dart';

part 'add_word_state.dart';

class AddWordCubit extends Cubit<AddWordState> {
  final VocabularyRepository _repo;

  AddWordCubit(this._repo) : super(AddWordState());

  // ─── Field changes ────────────────────────────────────────
  void onVocabularyChanged(String value) =>
      emit(state.copyWith(vocabulary: value));

  void onFuriganaChanged(String value) =>
      emit(state.copyWith(furigana: value));

  void onMeaningChanged(String value) =>
      emit(state.copyWith(meaning: value));

  void onWordTypeChanged(String value) =>
      emit(state.copyWith(wordType: value));

  void onJlptLevelChanged(String value) =>
      emit(state.copyWith(jlptLevel: value));

  // ─── Save ─────────────────────────────────────────────────
  Future<void> saveWord() async {
    // Validate
    if (state.vocabulary.trim().isEmpty) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Vui lòng nhập từ vựng',
      ));
      return;
    }
    if (state.meaning.trim().isEmpty) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Vui lòng nhập nghĩa',
      ));
      return;
    }

    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));

    try {
      print("da nhap tu");
      final entry = VocabularyEntriesCompanion.insert(
        word: state.vocabulary.trim(),
        meaning: state.meaning.trim(),
        pronunciation: state.furigana.trim().isNotEmpty
            ? Value(state.furigana.trim())
            : const Value.absent(),
      );
      print("da nhap tu $entry");
      await _repo.insertWord(entry);
      emit(state.copyWith(loadstatus: LOADSTATUS.SUCCESS));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Lưu thất bại: $e',
      ));
    }
  }

  // ─── Reset ────────────────────────────────────────────────
  void reset() => emit(AddWordState());
}