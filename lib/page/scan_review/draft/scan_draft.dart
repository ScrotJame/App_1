import 'package:equatable/equatable.dart';

import 'scan_card.dart';

/// Danh sách thẻ của một lần quét. Bất biến; mọi thao tác trả bản mới, thao
/// tác không hợp lệ trả lại chính nó.
class ScanDraft extends Equatable {
  const ScanDraft({
    this.cards = const [],
    this.history = const [],
    this.defaultUnitId,
    this.nextId = 1,
  });

  /// Theo thứ tự thêm.
  final List<ScanCard> cards;

  /// Id các thẻ đã quyết định, theo thứ tự quyết định.
  final List<int> history;

  /// Unit của thẻ thêm mới.
  final int? defaultUnitId;
  final int nextId;

  List<ScanCard> get pending =>
      cards.where((c) => c.decision == CardDecision.pending).toList();

  List<ScanCard> get kept =>
      cards.where((c) => c.decision == CardDecision.kept).toList();

  ScanCard? get current => pending.firstOrNull;

  ScanCard? get next => pending.skip(1).firstOrNull;

  int get discardedCount =>
      cards.where((c) => c.decision == CardDecision.discarded).length;

  /// Số thẻ sẽ mất nếu thoát mà chưa lưu.
  int get unsavedCount => cards.length - discardedCount;

  bool get hasUnsavedCards => unsavedCount > 0;

  bool get isReviewed => cards.isNotEmpty && current == null;

  bool get canUndo => history.isNotEmpty;

  ScanDraft add({
    required String word,
    String pronunciation = '',
    String meaning = '',
    String language = '',
  }) {
    final card = ScanCard(
      id: nextId,
      word: word,
      pronunciation: pronunciation,
      meaning: meaning,
      language: language,
      unitId: defaultUnitId,
    );
    return _copy(cards: [...cards, card], nextId: nextId + 1);
  }

  ScanDraft edit(
    int id, {
    required String word,
    required String pronunciation,
    required String meaning,
    required String language,
    required Set<int> tagIds,
  }) {
    return _update(id, (old) {
      final pronEdited = pronunciation != old.pronunciation;
      final sourceChanged =
          word.trim() != old.word.trim() || language != old.language;
      final regenerate = !pronEdited &&
          sourceChanged &&
          (old.pronunciationAuto || old.pronunciation.isEmpty);
      return old.copyWith(
        word: word,
        meaning: meaning,
        language: language,
        tagIds: tagIds,
        pronunciation: regenerate ? '' : pronunciation,
        pronunciationAuto:
            pronEdited || regenerate ? false : old.pronunciationAuto,
        pronunciationChecked:
            regenerate ? false : pronEdited || old.pronunciationChecked,
      );
    });
  }

  /// Áp cho thẻ [id], mọi thẻ chưa quyết định phía sau và thẻ thêm mới.
  ScanDraft setUnit(int id, int? unitId) {
    final start = cards.indexWhere((c) => c.id == id);
    if (start < 0) return this;
    return ScanDraft(
      cards: [
        for (var i = 0; i < cards.length; i++)
          i == start ||
                  (i > start && cards[i].decision == CardDecision.pending)
              ? cards[i].withUnit(unitId)
              : cards[i],
      ],
      history: history,
      defaultUnitId: unitId,
      nextId: nextId,
    );
  }

  /// Ghi cách đọc sinh cho [requested]. Bỏ qua nếu thẻ đã đổi từ hoặc ngôn
  /// ngữ trong lúc chờ, hoặc đã có cách đọc.
  ScanDraft applyPronunciation(ScanCard requested, String? value) {
    return _update(requested.id, (card) {
      if (card.pronunciationChecked ||
          card.pronunciation.isNotEmpty ||
          card.word != requested.word ||
          card.language != requested.language) {
        return card;
      }
      final reading = value ?? '';
      return card.copyWith(
        pronunciation: reading,
        pronunciationAuto: reading.isNotEmpty,
        pronunciationChecked: true,
      );
    });
  }

  ScanDraft keep(int id) {
    final card = current;
    if (card == null || card.id != id || !card.isComplete) return this;
    return _decide(id, CardDecision.kept);
  }

  ScanDraft discard(int id) {
    if (current?.id != id) return this;
    return _decide(id, CardDecision.discarded);
  }

  ScanDraft undo() {
    if (history.isEmpty) return this;
    return _update(
      history.last,
      (c) => c.copyWith(decision: CardDecision.pending),
    )._copy(history: history.sublist(0, history.length - 1));
  }

  ScanDraft _decide(int id, CardDecision decision) {
    return _update(id, (c) => c.copyWith(decision: decision))
        ._copy(history: [...history, id]);
  }

  ScanDraft _update(int id, ScanCard Function(ScanCard) change) {
    return _copy(cards: [
      for (final card in cards) card.id == id ? change(card) : card,
    ]);
  }

  ScanDraft _copy({List<ScanCard>? cards, List<int>? history, int? nextId}) {
    return ScanDraft(
      cards: cards ?? this.cards,
      history: history ?? this.history,
      defaultUnitId: defaultUnitId,
      nextId: nextId ?? this.nextId,
    );
  }

  @override
  List<Object?> get props => [cards, history, defaultUnitId, nextId];
}
