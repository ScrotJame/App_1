import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/unit_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../scan_vocab/scan_vocab_cubit.dart';
import 'package:test_abc/generated/l10n.dart';

part 'batch_add_word_state.dart';

class BatchAddWordCubit extends Cubit<BatchAddWordState> {
  final VocabularyRepository _repo;
  final TagRepository _tagRepository;
  final UnitRepository _unitRepository;

  /// Unit the scan was opened from; null saves the words outside any unit.
  final int? unitId;

  /// One-shot error messages for the page (shown once, never kept in state).
  final PublishSubject<String> messageController = PublishSubject();

  BatchAddWordCubit(
      this._repo,
      this._tagRepository,
      this._unitRepository,
      List<ScannedVocabItem> items,
      String? detectedLanguage, {
      this.unitId,
      }) : super(BatchAddWordState(items: List.unmodifiable(items), detectedLanguage: detectedLanguage));

  // ─── Load tags ─────────────────────────────────────────────────────────────
  Future<void> loadTags() async {
    try {
      final tags = await _tagRepository.getAllTags();
      emit(state.copyWith(tags: tags));
    } catch (e) {
      messageController.add(S.current.error_load_tags(e.toString()));
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
  /// Saves every item in one transaction: either all new words are stored
  /// (in [unitId], with their tags) or none is. A word whose
  /// `word + meaning + unit` is already stored is skipped, and so is a repeat
  /// inside the list (its tags go to the copy that is saved).
  Future<void> saveAll() async {
    if (state.status == LOADSTATUS.LOADING) return;

    final invalidCount = state.items.where((i) => i.hasError).length;
    if (invalidCount > 0) {
      messageController.add(S.current.batch_missing_fields(invalidCount));
      return;
    }

    // One entry per identity, in list order, with the tags of all its copies.
    final unique = <(String, String), _BatchWord>{};
    for (int i = 0; i < state.items.length; i++) {
      final item = state.items[i];
      final word = item.word.trim();
      final meaning = item.meaning.trim();
      final entry = unique.putIfAbsent(
        (word, meaning),
        () => _BatchWord(item: item, word: word, meaning: meaning),
      );
      entry.tagIds.addAll(state.tagsForItem(i));
    }

    emit(state.copyWith(status: LOADSTATUS.LOADING));

    try {
      final saved = await _repo.transaction(() async {
        int count = 0;
        for (final entry in unique.values) {
          final exists = await _repo.wordExists(
            word: entry.word,
            meaning: entry.meaning,
            unitId: unitId,
          );
          if (exists) continue;

          final pronunciation = entry.item.pronunciation.trim();
          final wordId = await _repo.insertWord(
            word: entry.word,
            meaning: entry.meaning,
            pronunciation: pronunciation.isNotEmpty ? pronunciation : null,
            language: entry.item.language.trim(),
          );
          final targetUnitId = unitId;
          if (targetUnitId != null) {
            await _unitRepository.addWordToUnit(
                wordId: wordId, unitId: targetUnitId);
          }
          for (final tagId in entry.tagIds) {
            await _repo.attachTag(wordId: wordId, tagId: tagId);
          }
          count++;
        }
        return count;
      });
      // Skipped = repeats inside the list + words already stored.
      emit(state.copyWith(
        status: LOADSTATUS.SUCCESS,
        savedCount: saved,
        skippedCount: state.items.length - saved,
      ));
    } catch (e) {
      emit(state.copyWith(status: LOADSTATUS.FAILED));
      messageController.add(S.current.error_save(e.toString()));
    }
  }

  @override
  Future<void> close() {
    messageController.close();
    return super.close();
  }
}

class _BatchWord {
  _BatchWord({required this.item, required this.word, required this.meaning});

  final ScannedVocabItem item;
  final String word;
  final String meaning;
  final Set<int> tagIds = {};
}
