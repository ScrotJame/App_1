import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';

import '../../commons/enums.dart';
import '../../models/tag_vocab.dart';
import '../../repository/vocabulary_repository.dart';

part 'list_word_state.dart';

class ListWordCubit extends Cubit<ListWordState> {
  final VocabularyRepository _repo;

  ListWordCubit(this._repo) : super(const ListWordState());

  // ─── Load ─────────────────────────────────────────────────
  Future<void> loadWords() async {
    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));
    try {
      final words = await _repo.watchAllWordsWithTags().first;
      emit(state.copyWith(
        allWords: words,
        filteredWords: _applyFilter(words, state.activeTab, state.searchQuery),
        loadstatus: LOADSTATUS.SUCCESS,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  // ─── Filter tab ───────────────────────────────────────────
  void onTabChanged(FilterTab tab) {
    final filtered = _applyFilter(state.allWords, tab, state.searchQuery);
    emit(state.copyWith(activeTab: tab, filteredWords: filtered));
  }

  // ─── Search ───────────────────────────────────────────────
  void toggleSearch() {
    if (state.isSearching) {
      final filtered = _applyFilter(state.allWords, state.activeTab, '');
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
    final filtered = _applyFilter(state.allWords, state.activeTab, query);
    emit(state.copyWith(searchQuery: query, filteredWords: filtered));
  }

  // ─── Toggle learned ───────────────────────────────────────
  Future<void> toggleLearned(int id) async {
    try {
      // await _repo.updateLearnedStatus(id, newValue);
      await loadWords();
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Cập nhật thất bại: $e',
      ));
    }
  }

  // ─── Delete ───────────────────────────────────────────────
  Future<void> deleteWord(int id) async {
    try {
      await _repo.deleteWord(id);
      await loadWords();
    } catch (e) {
      emit(state.copyWith(
        loadstatus: LOADSTATUS.FAILED,
        errorMessage: 'Xóa thất bại: $e',
      ));
    }
  }

  // ─── Private helper ───────────────────────────────────────
  List<VocabularyWithTags> _applyFilter(
      List<VocabularyWithTags> words,
      FilterTab tab,
      String query,
      ) {
    List<VocabularyWithTags> result = words;

    switch (tab) {
      case FilterTab.learned:
        result = result.where((w) => w.word.isFavorite == true).toList();
        break;
      case FilterTab.newWord:
        result = result.where((w) => w.word.isFavorite != true).toList();
        break;
      case FilterTab.all:
        break;
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((w) {
        return w.word.word.toLowerCase().contains(q) ||
            w.word.meaning.toLowerCase().contains(q) ||
            (w.word.pronunciation?.toLowerCase().contains(q) ?? false) ||
            w.tags.any((t) => t.tagName.toLowerCase().contains(q));
      }).toList();
    }

    return result;
  }
}