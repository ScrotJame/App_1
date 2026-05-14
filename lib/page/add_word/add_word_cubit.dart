import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/tag_repository.dart';

import '../../commons/enums.dart';
import '../../helper/language_helper.dart';
import '../../models/model_local/support_language_local.dart';
import '../../repository/vocabulary_repository.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

import '../scan_vocab/scan_vocab_cubit.dart';
part 'add_word_state.dart';

class AddWordCubit extends Cubit<AddWordState> {
  final VocabularyRepository _repo;
  final TagRepository _tagRepository;

  AddWordCubit(this._repo, this._tagRepository) : super(AddWordState());

  // ─── Khởi tạo dữ liệu khi ở mode Put ─────────────────────
  Future<void> initForEdit(VocabularyEntry entry) async {
    emit(state.copyWith(
      vocabulary: entry.word,
      furigana: entry.pronunciation ?? '',
      meaning: entry.meaning,
      loadstatus: LOADSTATUS.INITAL,
    ));
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

  Future<void> detectLanguage(String text) async {
    if (text.trim().length < 2) {
      emit(state.copyWith(detectedLanguage: null));
      return;
    }

    emit(state.copyWith(languageDetectStatus: LOADSTATUS.LOADING));

    try {
      final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final lang = await identifier.identifyLanguage(text.trim());
      await identifier.close();

      emit(state.copyWith(
        detectedLanguage: lang == 'und' ? null : lang,
        languageDetectStatus: LOADSTATUS.SUCCESS,
      ));
    } catch (e) {
      emit(state.copyWith(languageDetectStatus: LOADSTATUS.FAILED));
    }
  }

  void setLanguageManually(String lang) {
    emit(state.copyWith(
      detectedLanguage: lang,
      isLanguageManuallySet: true,
      languageDetectStatus: LOADSTATUS.SUCCESS,
    ));
  }

  void clearManualLanguage() {
    final vocab = state.vocabulary;
    emit(state.copyWith(clearLanguage: true));
    if (vocab.trim().isNotEmpty) {
      detectLanguage(vocab);
    }
  }

  // ─── Field changes ────────────────────────────────────────
  void onVocabularyChanged(String value) {
    if (value.trim().isEmpty) {
      emit(state.copyWith(vocabulary: value, clearLanguage: true));
      return;
    }
    emit(state.copyWith(vocabulary: value));
    if (!state.isLanguageManuallySet) {
      detectLanguage(value);
    }
  }

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
          language: state.detectedLanguage?.trim()
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
          language: state.detectedLanguage?.trim()
      );
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

  void clearWord() {
    emit(state.copyWith(
      vocabulary: '',
      clearLanguage: true,
    ));
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