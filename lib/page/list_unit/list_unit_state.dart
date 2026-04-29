part of 'list_unit_cubit.dart';

enum UnitSortOrder { byId, byTitle, byWordCount }

class ListUnitState extends Equatable {
  const ListUnitState({
    this.allUnits = const [],
    this.filteredUnits = const [],
    this.expandedUnitIds = const {},
    this.searchQuery = '',
    this.isSearching = false,
    this.sortOrder = UnitSortOrder.byId,
    this.loadStatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  /// Toàn bộ unit lấy từ DB (kèm danh sách từ vựng)
  final List<UnitWithWords> allUnits;

  /// Danh sách hiển thị sau khi search/sort
  final List<UnitWithWords> filteredUnits;

  /// Tập hợp id của các unit đang expand
  final Set<int> expandedUnitIds;

  final String searchQuery;
  final bool isSearching;
  final UnitSortOrder sortOrder;
  final LOADSTATUS loadStatus;
  final String? errorMessage;

  // ─── Computed ─────────────────────────────────────────────
  int get totalUnitCount => allUnits.length;
  int get totalWordCount =>
      allUnits.fold(0, (sum, u) => sum + u.words.length);

  bool isExpanded(int unitId) => expandedUnitIds.contains(unitId);

  // ─── CopyWith ─────────────────────────────────────────────
  ListUnitState copyWith({
    List<UnitWithWords>? allUnits,
    List<UnitWithWords>? filteredUnits,
    Set<int>? expandedUnitIds,
    String? searchQuery,
    bool? isSearching,
    UnitSortOrder? sortOrder,
    LOADSTATUS? loadStatus,
    String? errorMessage,
  }) {
    return ListUnitState(
      allUnits: allUnits ?? this.allUnits,
      filteredUnits: filteredUnits ?? this.filteredUnits,
      expandedUnitIds: expandedUnitIds ?? this.expandedUnitIds,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      sortOrder: sortOrder ?? this.sortOrder,
      loadStatus: loadStatus ?? this.loadStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    allUnits,
    filteredUnits,
    expandedUnitIds,
    searchQuery,
    isSearching,
    sortOrder,
    loadStatus,
    errorMessage,
  ];
}