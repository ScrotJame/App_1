import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';

import '../../commons/enums.dart';
import '../../models/tag_vocab.dart';
import '../../models/unit_entity.dart';
import '../../repository/unit_repository.dart';
import '../../repository/vocabulary_repository.dart';

part 'list_word_state.dart';

class ListWordCubit extends Cubit<ListWordState> {
  final VocabularyRepository _repo;
  final UnitRepository? _unitRepo;
  final int? _unitId; // non-null = đang xem list từ của unit cụ thể

  StreamSubscription<List<UnitWithWords>>? _unitStreamSub;

  /// Dùng khi xem toàn bộ từ vựng
  ListWordCubit(this._repo)
      : _unitRepo = null,
        _unitId = null,
        super(const ListWordState());

  /// Dùng khi xem từ vựng của một unit — tự watch stream DB
  ListWordCubit.forUnit(this._repo, UnitRepository unitRepo, int unitId)
      : _unitRepo = unitRepo,
        _unitId = unitId,
        super(const ListWordState());

  /// Gọi trong initState khi ở unit mode — subscribe stream DB để realtime
  void watchUnit() {
    if (_unitRepo == null || _unitId == null) return;

    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));

    _unitStreamSub = _unitRepo!.watchAllUnitsWithWords().listen(
          (units) {
        final match = units.where((u) => u.unit.id == _unitId).firstOrNull;
        if (match == null) return;

        final withTags = match.words
            .map((w) => VocabularyWithTags(word: w, languageTags: w.language))
            .toList();

        emit(state.copyWith(
          allWords: withTags,
          filteredWords: _applyFilter(withTags, state.activeLanguage, state.searchQuery),
          unitWordCount: match.words.length,
          loadstatus: LOADSTATUS.SUCCESS,
        ));
      },
      onError: (e) => emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      )),
    );
  }

  /// Gọi sau khi thêm từ vào unit để đảm bảo list luôn cập nhật,
  /// dùng làm fallback nếu stream không tự emit (tuỳ implementation của UnitRepository).
  Future<void> reloadUnit() async {
    if (_unitRepo == null || _unitId == null) return;
    try {
      final units = await _unitRepo!.watchAllUnitsWithWords().first;
      final match = units.where((u) => u.unit.id == _unitId).firstOrNull;
      if (match == null) return;

      final withTags = match.words
          .map((w) => VocabularyWithTags(word: w, languageTags: w.language))
          .toList();

      emit(state.copyWith(
        allWords: withTags,
        filteredWords: _applyFilter(withTags, state.activeLanguage, state.searchQuery),
        unitWordCount: match.words.length,
        loadstatus: LOADSTATUS.SUCCESS,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  Future<void> loadWords() async {
    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));
    try {
      final words = await _repo.watchAllWordsWithTags().first;
      emit(state.copyWith(
        allWords: words,
        filteredWords: _applyFilter(words, state.activeLanguage, state.searchQuery),
        loadstatus: LOADSTATUS.SUCCESS,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  /// Giữ lại để tương thích ngược
  Future<void> loadFromUnit(List<VocabularyEntry> words) async {
    final withTags = words
        .map((w) => VocabularyWithTags(word: w, languageTags: w.language))
        .toList();

    emit(state.copyWith(
      allWords: withTags,
      filteredWords: _applyFilter(withTags, null, state.searchQuery),
      unitWordCount: words.length,
      loadstatus: LOADSTATUS.SUCCESS,
    ));
  }

  Future<void> getLanguageTags() async {
    try {
      final tags = await _repo.getLanguageTags();
      emit(state.copyWith(languageTags: tags));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải tag thất bại: $e',
      ));
    }
  }

  void onLanguageChanged(String? language) async {
    if (language == null) {
      final filtered = _applyFilter(state.allWords, null, state.searchQuery);
      emit(state.copyWith(clearActiveLanguage: true, filteredWords: filtered));
    } else {
      try {
        final res = await _repo.getWordsByLanguageTags(language);
        final wordsWithTags = res
            .map((e) => VocabularyWithTags(word: e, languageTags: e.language))
            .toList();

        final filtered = _applyFilter(wordsWithTags, null, state.searchQuery);
        emit(state.copyWith(activeLanguage: language, filteredWords: filtered));
      } catch (e) {
        emit(state.copyWith(
          loadstatus: LOADSTATUS.FAILED,
          errorMessage: 'Tải dữ liệu thất bại: $e',
        ));
      }
    }
  }

  void toggleSearch() {
    if (state.isSearching) {
      final filtered = _applyFilter(state.allWords, state.activeLanguage, '');
      emit(state.copyWith(
        isSearching: false,
        searchQuery: '',
        filteredWords: filtered,
      ));
    } else {
      emit(state.copyWith(isSearching: true));
    }
  }

  void onSearchChanged(String query) {
    final filtered = _applyFilter(state.allWords, state.activeLanguage, query);
    emit(state.copyWith(searchQuery: query, filteredWords: filtered));
  }

  Future<void> toggleLearned(int id) async {
    try {
      await loadWords();
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Cập nhật thất bại: $e',
      ));
    }
  }

  Future<void> deleteWord(int id) async {
    try {
      await _repo.deleteWord(id);
      if (_unitId != null) {
        await reloadUnit();
      } else {
        await loadWords();
      }
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Xóa thất bại: $e',
      ));
    }
  }

  List<VocabularyWithTags> _applyFilter(
      List<VocabularyWithTags> words,
      String? language,
      String query,
      ) {
    List<VocabularyWithTags> result = words;

    if (language != null) {
      result = result
          .where((w) => w.word.language?.toLowerCase() == language.toLowerCase())
          .toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((w) {
        return w.word.word.toLowerCase().contains(q) ||
            w.word.meaning.toLowerCase().contains(q) ||
            (w.word.pronunciation?.toLowerCase().contains(q) ?? false) ||
            (w.tags?.any((t) => t.tagName.toLowerCase().contains(q)) ?? false);
      }).toList();
    }

    return result;
  }

  @override
  Future<void> close() {
    _unitStreamSub?.cancel();
    return super.close();
  }
}