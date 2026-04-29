part of 'batch_add_word_cubit.dart';

class BatchAddWordState extends Equatable {
  final List<ScannedVocabItem> items;
  final List<Tag>? tags;

  /// key = index của item, value = list tagId được chọn
  final Map<int, List<int>> selectedTagIds;
  final LOADSTATUS status;
  final String? errorMessage;
  final int savedCount;

  const BatchAddWordState({
    required this.items,
    this.tags,
    this.selectedTagIds = const {},
    this.status = LOADSTATUS.INITAL,
    this.errorMessage,
    this.savedCount = 0,
  });

  List<int> tagsForItem(int index) => selectedTagIds[index] ?? const [];

  bool isTagSelected(int itemIndex, int tagId) =>
      tagsForItem(itemIndex).contains(tagId);

  BatchAddWordState copyWith({
    List<ScannedVocabItem>? items,
    List<Tag>? tags,
    Map<int, List<int>>? selectedTagIds,
    LOADSTATUS? status,
    String? errorMessage,
    int? savedCount,
  }) {
    return BatchAddWordState(
      items: items ?? this.items,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      savedCount: savedCount ?? this.savedCount,
    );
  }

  @override
  List<Object?> get props => [items, tags, selectedTagIds, status, errorMessage, savedCount];
}