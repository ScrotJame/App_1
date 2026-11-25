import 'package:equatable/equatable.dart';

enum CardDecision { pending, kept, discarded }

/// Vì sao một thẻ bị cảnh báo trùng.
enum DuplicateKind { none, stored, inDraft }

/// Một từ quét được, đang chờ duyệt.
class ScanCard extends Equatable {
  const ScanCard({
    required this.id,
    this.word = '',
    this.pronunciation = '',
    this.meaning = '',
    this.language = '',
    this.unitId,
    this.tagIds = const {},
    this.decision = CardDecision.pending,
    this.pronunciationAuto = false,
    this.pronunciationChecked = false,
  });

  final int id;
  final String word;
  final String pronunciation;
  final String meaning;
  final String language;

  /// null là không thuộc Unit nào.
  final int? unitId;
  final Set<int> tagIds;
  final CardDecision decision;

  /// Cách đọc do app sinh ra.
  final bool pronunciationAuto;

  /// Không cần sinh cách đọc nữa (đã thử, hoặc người dùng đã nhập).
  final bool pronunciationChecked;

  bool get isComplete => word.trim().isNotEmpty && meaning.trim().isNotEmpty;

  /// Không đổi [unitId]; dùng [withUnit].
  ScanCard copyWith({
    String? word,
    String? pronunciation,
    String? meaning,
    String? language,
    Set<int>? tagIds,
    CardDecision? decision,
    bool? pronunciationAuto,
    bool? pronunciationChecked,
  }) {
    return ScanCard(
      id: id,
      word: word ?? this.word,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
      language: language ?? this.language,
      unitId: unitId,
      tagIds: tagIds ?? this.tagIds,
      decision: decision ?? this.decision,
      pronunciationAuto: pronunciationAuto ?? this.pronunciationAuto,
      pronunciationChecked: pronunciationChecked ?? this.pronunciationChecked,
    );
  }

  ScanCard withUnit(int? unitId) {
    return ScanCard(
      id: id,
      word: word,
      pronunciation: pronunciation,
      meaning: meaning,
      language: language,
      unitId: unitId,
      tagIds: tagIds,
      decision: decision,
      pronunciationAuto: pronunciationAuto,
      pronunciationChecked: pronunciationChecked,
    );
  }

  @override
  List<Object?> get props => [
        id, word, pronunciation, meaning, language, unitId, tagIds,
        decision, pronunciationAuto, pronunciationChecked,
      ];
}
