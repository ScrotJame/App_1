import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../scan_vocab/scan_vocab_cubit.dart';

part 'batch_add_word_state.dart';

class BatchAddWordCubit extends Cubit<BatchAddWordState> {
  final VocabularyRepository _repo;
  final TagRepository _tagRepository;

  BatchAddWordCubit(
      this._repo,
      this._tagRepository,
      List<ScannedVocabItem> items,
      String? detectedLanguage,
      ) : super(BatchAddWordState(items: List.unmodifiable(items), detectedLanguage: detectedLanguage));

  // ─── Load tags ─────────────────────────────────────────────────────────────
  Future<void> loadTags() async {
    try {
      final tags = await _tagRepository.getAllTags();
      emit(state.copyWith(tags: tags));
    } catch (e) {
      emit(state.copyWith(status: LOADSTATUS.FAILED, errorMessage: 'Tải tag thất bại: $e'));
    }
  }

  // ─── Cập nhật nội dung 1 item ──────────────────────────────────────────────
  void updateItem(int index, ScannedVocabItem item) {
    final list = List<ScannedVocabItem>.from(state.items)..[index] = item;
    emit(state.copyWith(items: list));
  }

  // ─── Xoá 1 item và re-index map tag ───────────────────────────────────────
  void removeItem(int index) {
    final list = List<ScannedVocabItem>.from(state.items)..removeAt(index);

    final reindexed = <int, List<int>>{};
    state.selectedTagIds.forEach((k, v) {
      if (k < index) reindexed[k] = v;
      if (k > index) reindexed[k - 1] = v;
      // k == index bị bỏ đi
    });

    emit(state.copyWith(items: list, selectedTagIds: reindexed));
  }

  // ─── Toggle tag cho 1 item ─────────────────────────────────────────────────
  void toggleTag(int itemIndex, int tagId) {
    final map = Map<int, List<int>>.from(state.selectedTagIds);
    final current = List<int>.from(map[itemIndex] ?? []);
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      current.add(tagId);
    }
    map[itemIndex] = current;
    emit(state.copyWith(selectedTagIds: map));
  }

  // ─── Lưu toàn bộ ──────────────────────────────────────────────────────────
  Future<void> saveAll() async {
    final invalidCount = state.items.where((i) => i.hasError).length;
    if (invalidCount > 0) {
      emit(state.copyWith(
        status: LOADSTATUS.FAILED,
        errorMessage: '$invalidCount từ đang thiếu Từ vựng hoặc Nghĩa',
      ));
      return;
    }

    emit(state.copyWith(status: LOADSTATUS.LOADING));

    try {
      int count = 0;
      for (int i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        final wordId = await _repo.insertWord(
          word: item.word.trim(),
          meaning: item.meaning.trim(),
          pronunciation: item.pronunciation.trim().isNotEmpty ? item.pronunciation.trim() : null,
          language: item.language.trim(),
        );
        for (final tagId in state.tagsForItem(i)) {
          await _repo.attachTag(wordId: wordId, tagId: tagId);
        }
        count++;
      }
      emit(state.copyWith(status: LOADSTATUS.SUCCESS, savedCount: count));
    } catch (e) {
      emit(state.copyWith(status: LOADSTATUS.FAILED, errorMessage: 'Lưu thất bại: $e'));
    }
  }
}