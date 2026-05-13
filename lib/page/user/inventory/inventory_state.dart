part of 'inventory_cubit.dart';

enum InventoryStatus { initial, loading, loaded, error }

enum ItemCategory { all, weapon, armor, potion, food, quest, companion }

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final ItemCategory category;
  final String? imagePath;   // asset path hoặc network url
  final String action;       // label nút hành động: Equip, Use, Eat, Inspect, Hatch...

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    this.imagePath,
    required this.action,
  });

  @override
  List<Object?> get props => [id, name, category, imagePath, action];
}

class InventoryState extends Equatable {
  final InventoryStatus status;
  final List<InventoryItem> allItems;
  final ItemCategory selectedCategory;
  final String searchQuery;
  final String? errorMessage;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.allItems = const [],
    this.selectedCategory = ItemCategory.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  /// Items sau khi lọc theo category + search
  List<InventoryItem> get filteredItems {
    var items = allItems;
    if (selectedCategory != ItemCategory.all) {
      items = items.where((i) => i.category == selectedCategory).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      items = items.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  InventoryState copyWith({
    InventoryStatus? status,
    List<InventoryItem>? allItems,
    ItemCategory? selectedCategory,
    String? searchQuery,
    String? errorMessage,
  }) {
    return InventoryState(
      status: status ?? this.status,
      allItems: allItems ?? this.allItems,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allItems,
    selectedCategory,
    searchQuery,
    errorMessage,
  ];
}