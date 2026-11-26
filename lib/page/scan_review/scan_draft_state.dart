part of 'scan_draft_cubit.dart';

class ScanDraftState extends Equatable {
  const ScanDraftState({
    this.draft = const ScanDraft(),
    this.tags = const [],
    this.units = const [],
    this.duplicates = const {},
    this.loadStatus = LOADSTATUS.INITAL,
    this.isCheckingDuplicates = false,
    this.saveStatus = LOADSTATUS.INITAL,
    this.savedCount = 0,
  });

  final ScanDraft draft;
  final List<Tag> tags;
  final List<UnitsEntry> units;

  /// key = id thẻ; thẻ không có trong map là không trùng.
  final Map<int, DuplicateKind> duplicates;
  final LOADSTATUS loadStatus;
  final bool isCheckingDuplicates;
  final LOADSTATUS saveStatus;
  final int savedCount;

  bool get isSaving => saveStatus == LOADSTATUS.LOADING;

  /// Chỉ giữ được khi cảnh báo trùng của thẻ đã hiện đúng.
  bool get canKeep =>
      loadStatus == LOADSTATUS.SUCCESS && !isCheckingDuplicates && !isSaving;

  bool get hasUnsaved =>
      saveStatus != LOADSTATUS.SUCCESS && draft.hasUnsavedCards;

  DuplicateKind duplicateOf(int id) => duplicates[id] ?? DuplicateKind.none;

  ScanDraftState copyWith({
    ScanDraft? draft,
    List<Tag>? tags,
    List<UnitsEntry>? units,
    Map<int, DuplicateKind>? duplicates,
    LOADSTATUS? loadStatus,
    bool? isCheckingDuplicates,
    LOADSTATUS? saveStatus,
    int? savedCount,
  }) {
    return ScanDraftState(
      draft: draft ?? this.draft,
      tags: tags ?? this.tags,
      units: units ?? this.units,
      duplicates: duplicates ?? this.duplicates,
      loadStatus: loadStatus ?? this.loadStatus,
      isCheckingDuplicates: isCheckingDuplicates ?? this.isCheckingDuplicates,
      saveStatus: saveStatus ?? this.saveStatus,
      savedCount: savedCount ?? this.savedCount,
    );
  }

  @override
  List<Object?> get props => [
        draft, tags, units, duplicates, loadStatus,
        isCheckingDuplicates, saveStatus, savedCount,
      ];
}
