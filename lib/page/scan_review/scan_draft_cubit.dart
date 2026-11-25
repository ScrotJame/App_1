import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/unit_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/service/pronunciation_service.dart';

import '../scan_vocab/scan_vocab_cubit.dart';
import 'draft/scan_card.dart';
import 'draft/scan_draft.dart';

part 'scan_draft_state.dart';

/// Giữ các thẻ quét được cho cả màn quét và màn duyệt, và lưu chúng.
class ScanDraftCubit extends Cubit<ScanDraftState> {
  ScanDraftCubit(
    this._vocabulary,
    this._tags,
    this._units,
    this._pronunciation, {
    int? defaultUnitId,
  }) : super(ScanDraftState(
            draft: ScanDraft(defaultUnitId: defaultUnitId)));

  final VocabularyRepository _vocabulary;
  final TagRepository _tags;
  final UnitRepository _units;
  final PronunciationService _pronunciation;

  /// Thông báo một lần cho trang.
  final PublishSubject<String> messageController = PublishSubject();

  /// Tăng mỗi lần kiểm tra trùng; kết quả cũ bị bỏ.
  int _checkSeq = 0;

  void addCard(ScannedVocabItem item) {
    if (isClosed || state.isSaving) return;
    emit(state.copyWith(
      draft: state.draft.add(
        word: item.word,
        pronunciation: item.pronunciation,
        meaning: item.meaning,
        language: item.language,
      ),
    ));
  }

  /// Gọi mỗi lần mở màn duyệt.
  Future<void> load() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));
    try {
      final tags = await _tags.getAllTags();
      final units = await _units.getAllUnits();
      if (isClosed) return;
      emit(state.copyWith(
        tags: tags,
        units: units,
        loadStatus: LOADSTATUS.SUCCESS,
      ));
      await _refreshDuplicates();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loadStatus: LOADSTATUS.FAILED));
      messageController.add(S.current.error_generic(e.toString()));
      return;
    }
    await _generatePronunciations();
  }

  Future<void> keep(int id) async {
    if (!state.canKeep) return;
    final card = state.draft.current;
    if (card == null || card.id != id) return;
    if (!card.isComplete) {
      messageController.add(S.current.scan_review_incomplete);
      return;
    }
    await _apply(state.draft.keep(id));
  }

  Future<void> discard(int id) async {
    if (state.isSaving) return;
    await _apply(state.draft.discard(id));
  }

  Future<void> undo() async {
    if (state.isSaving) return;
    await _apply(state.draft.undo());
  }

  Future<void> editCard(
    int id, {
    required String word,
    required String pronunciation,
    required String meaning,
    required String language,
    required Set<int> tagIds,
  }) async {
    if (state.isSaving) return;
    await _apply(state.draft.edit(
      id,
      word: word,
      pronunciation: pronunciation,
      meaning: meaning,
      language: language,
      tagIds: tagIds,
    ));
    await _generatePronunciations();
  }

  Future<void> setUnit(int id, int? unitId) async {
    if (state.isSaving) return;
    await _apply(state.draft.setUnit(id, unitId));
  }

  /// Ghi mọi thẻ đã giữ trong một transaction: được hết hoặc không gì cả.
  /// Thẻ trùng vẫn được ghi vì người dùng đã chọn giữ.
  Future<void> save() async {
    if (state.isSaving || state.saveStatus == LOADSTATUS.SUCCESS) return;
    final draft = state.draft;
    final kept = draft.kept;
    if (!draft.isReviewed || kept.isEmpty) return;

    emit(state.copyWith(saveStatus: LOADSTATUS.LOADING));
    try {
      await _vocabulary.transaction(() async {
        for (final card in kept) {
          final pronunciation = card.pronunciation.trim();
          final wordId = await _vocabulary.insertWord(
            word: card.word.trim(),
            meaning: card.meaning.trim(),
            pronunciation: pronunciation.isNotEmpty ? pronunciation : null,
            language: card.language.trim(),
          );
          final unitId = card.unitId;
          if (unitId != null) {
            await _units.addWordToUnit(wordId: wordId, unitId: unitId);
          }
          for (final tagId in card.tagIds) {
            await _vocabulary.attachTag(wordId: wordId, tagId: tagId);
          }
        }
      });
      if (isClosed) return;
      emit(state.copyWith(
        saveStatus: LOADSTATUS.SUCCESS,
        savedCount: kept.length,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(saveStatus: LOADSTATUS.FAILED));
      messageController.add(S.current.error_save(e.toString()));
    }
  }

  Future<void> _apply(ScanDraft draft) async {
    if (isClosed || draft == state.draft) return;
    emit(state.copyWith(draft: draft));
    await _refreshDuplicates();
  }

  /// Tính lại cảnh báo trùng cho bản nháp hiện tại. Lấy [_checkSeq] và bật cờ
  /// trong cùng một bước đồng bộ, nên lần kiểm tra mới hơn luôn là người xoá cờ.
  Future<void> _refreshDuplicates() async {
    final seq = ++_checkSeq;
    emit(state.copyWith(isCheckingDuplicates: true));
    try {
      final duplicates = await _findDuplicates(state.draft);
      if (isClosed || seq != _checkSeq) return;
      emit(state.copyWith(
          duplicates: duplicates, isCheckingDuplicates: false));
    } catch (e) {
      if (isClosed || seq != _checkSeq) return;
      emit(state.copyWith(isCheckingDuplicates: false));
      messageController.add(S.current.error_generic(e.toString()));
    }
  }

  Future<Map<int, DuplicateKind>> _findDuplicates(ScanDraft draft) async {
    final result = <int, DuplicateKind>{};
    final keptKeys = <(String, String, int?)>{};
    for (final card in draft.cards) {
      if (card.decision == CardDecision.discarded || !card.isComplete) {
        continue;
      }
      final word = card.word.trim();
      final meaning = card.meaning.trim();
      final key = (word, meaning, card.unitId);
      if (await _vocabulary.wordExists(
          word: word, meaning: meaning, unitId: card.unitId)) {
        result[card.id] = DuplicateKind.stored;
      } else if (keptKeys.contains(key)) {
        result[card.id] = DuplicateKind.inDraft;
      }
      if (card.decision == CardDecision.kept) keptKeys.add(key);
    }
    return result;
  }

  Future<void> _generatePronunciations() async {
    if (isClosed) return;
    final waiting = state.draft.pending
        .where((c) =>
            !c.pronunciationChecked &&
            c.pronunciation.isEmpty &&
            _pronunciation.isLanguageSupported(c.language))
        .toList();
    if (waiting.isEmpty) return;
    try {
      await _pronunciation.ensureInitialized();
      for (final card in waiting) {
        final reading = await _pronunciation.generatePronunciation(
            card.word.trim(), card.language);
        if (isClosed) return;
        emit(state.copyWith(
            draft: state.draft.applyPronunciation(card, reading)));
      }
    } catch (e) {
      if (isClosed) return;
      messageController
          .add(S.current.scan_pronunciation_failed(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _checkSeq++;
    messageController.close();
    return super.close();
  }
}
