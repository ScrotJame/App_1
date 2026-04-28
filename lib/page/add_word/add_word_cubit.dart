import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/tag_repository.dart';

import '../../commons/enums.dart';
import '../../repository/vocabulary_repository.dart';

part 'add_word_state.dart';

class AddWordCubit extends Cubit<AddWordState> {
  final VocabularyRepository _repo;
  final TagRepository _tagRepository;

  AddWordCubit(this._repo, this._tagRepository) : super(AddWordState());

  // ─── Khởi tạo dữ liệu khi ở mode Put ─────────────────────
  // FIX: async + load selectedTagIds từ DB
  Future<void> initForEdit(VocabularyEntry entry) async {
    emit(state.copyWith(
      vocabulary: entry.word,
      furigana: entry.pronunciation ?? '',
      meaning: entry.meaning,
      loadstatus: LOADSTATUS.INITAL,
    ));
    // Load tag ids đã gắn với từ này để hiển thị đúng trạng thái selected
    final tagIds = await _repo.getTagIdsByWordId(entry.id);
    emit(state.copyWith(selectedTagIds: tagIds));
  }

  // ─── Load toàn bộ tags ────────────────────────────────────
  Future<void> loadTags() async {
    try {
      final tags = await _tagRepository.getAllTags();
      emit(state.copyWith(tags: tags));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải tag thất bại: $e',
      ));
    }
  }

  // ─── Toggle tag chọn/bỏ chọn ─────────────────────────────
  void toggleTag(int tagId) {
    final current = List<int>.from(state.selectedTagIds);
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      current.add(tagId);
    }
    emit(state.copyWith(selectedTagIds: current));
  }

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

  // ─── Save (Add) ───────────────────────────────────────────
  Future<void> saveWord() async {
    if (!_validate()) return;

    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));

    try {
      final wordId = await _repo.insertWord(
        word: state.vocabulary.trim(),
        meaning: state.meaning.trim(),
        pronunciation:
        state.furigana.trim().isNotEmpty ? state.furigana.trim() : null,
      );
      for (final tagId in state.selectedTagIds) {
        await _repo.attachTag(wordId: wordId, tagId: tagId);
      }
      emit(state.copyWith(loadstatus: LOADSTATUS.SUCCESS));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Lưu thất bại: $e',
      ));
    }
  }

  // ─── Update (Put) ─────────────────────────────────────────
  Future<void> updateWord(int id) async {
    if (!_validate()) return;

    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));

    try {
      await _repo.updateWord(
        id: id,
        word: state.vocabulary.trim(),
        meaning: state.meaning.trim(),
        pronunciation:
        state.furigana.trim().isNotEmpty ? state.furigana.trim() : null,
      );
      // FIX: xóa toàn bộ tag cũ trước rồi gắn lại
      // để bỏ chọn tag có hiệu lực và tránh duplicate
      await _repo.detachAllTags(wordId: id);
      for (final tagId in state.selectedTagIds) {
        await _repo.attachTag(wordId: id, tagId: tagId);
      }
      emit(state.copyWith(loadstatus: LOADSTATUS.SUCCESS));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Cập nhật thất bại: $e',
      ));
    }
  }

  // ─── Validate dùng chung ──────────────────────────────────
  bool _validate() {
    if (state.vocabulary.trim().isEmpty) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Vui lòng nhập từ vựng',
      ));
      return false;
    }
    if (state.meaning.trim().isEmpty) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Vui lòng nhập nghĩa',
      ));
      return false;
    }
    return true;
  }

  // ─── Reset ────────────────────────────────────────────────
  void reset() => emit(AddWordState());
}