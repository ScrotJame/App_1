part of 'inventory_cubit.dart';

class InventoryState extends Equatable {
  final LOADSTATUS status;
  final List<UserItemEntity> allItems;
  final String searchQuery;
  final String? errorMessage;

  const InventoryState({
    this.status      = LOADSTATUS.INITAL,
    this.allItems    = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  // ─── Derived ──────────────────────────────────────────────────────

  List<UserItemEntity> get filteredItems {
    if (searchQuery.trim().isEmpty) return allItems;
    final q = searchQuery.trim().toLowerCase();
    return allItems
        .where((e) => (e.item?.name ?? '').toLowerCase().contains(q))
        .toList();
  }

  // ─── copyWith ─────────────────────────────────────────────────────

  InventoryState copyWith({
    LOADSTATUS? status,
    List<UserItemEntity>? allItems,
    String? searchQuery,
    String? errorMessage,
  }) =>
      InventoryState(
        status:       status       ?? this.status,
        allItems:     allItems     ?? this.allItems,
        searchQuery:  searchQuery  ?? this.searchQuery,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, allItems, searchQuery, errorMessage];
}