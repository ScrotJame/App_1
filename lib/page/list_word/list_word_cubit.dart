import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';

import '../../commons/enums.dart';
import '../../repository/vocabulary_repository.dart';

part 'list_word_state.dart';

class ListWordCubit extends Cubit<ListWordState> {
  final VocabularyRepository _repo;

  ListWordCubit(this._repo) : super(const ListWordState());

  // ─── Load ─────────────────────────────────────────────────

  Future<void> loadWords() async {
    emit(state.copyWith(loadstatus: LOADSTATUS.LOADING));
    try {
      final words = await _repo.getAllWords();
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
    // Khi đóng search bar → reset query
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
      final word = state.allWords.firstWhere((w) => w.id == id);
      final newValue = !(word.isFavorite ?? false);
      // await _repo.updateLearnedStatus(id, newValue);
      await loadWords(); // reload để đồng bộ DB
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

  List<VocabularyEntry> _applyFilter(
      List<VocabularyEntry> words,
      FilterTab tab,
      String query,
      ) {
    List<VocabularyEntry> result = words;

    // Filter theo tab
    switch (tab) {
      case FilterTab.learned:
        result = result.where((w) => w.isFavorite == true).toList();
        break;
      case FilterTab.newWord:
        result = result.where((w) => w.isFavorite != true).toList();
        break;
      case FilterTab.all:
        break;
    }

    // Filter theo search query
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((w) {
        return w.word.toLowerCase().contains(q) ||
            w.meaning.toLowerCase().contains(q) ||
            (w.pronunciation?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }
}