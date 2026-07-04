part of 'shop_cubit.dart';

class ShopState extends Equatable {
  final ShopStatus status;
  final List<ItemsEntity> items;
  final String? purchasedItemId;
  final String searchQuery;
  final String? errorMessage;

  const ShopState({
    this.status = ShopStatus.initial,
    this.items = const [],
    this.purchasedItemId,
    this.errorMessage,
    this.searchQuery = '',
  });

  ShopState copyWith({
    ShopStatus? status,
    List<ItemsEntity>? items,
    String? purchasedItemId,
    String? errorMessage,
    String? searchQuery,
  }) {
    return ShopState(
      status: status ?? this.status,
      items: items ?? this.items,
      purchasedItemId: purchasedItemId ?? this.purchasedItemId,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery
    );
  }

  List<ItemsEntity> get filteredItems {
    if (searchQuery.trim().isEmpty) return items;
    final q = searchQuery.trim().toLowerCase();
    return items.where((i) {
      final name = i.name?.toLowerCase() ?? '';
      final desc = i.description?.toLowerCase() ?? '';
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  List<Object?> get props => [
    status,
    items,
    purchasedItemId,
    errorMessage,
    searchQuery];
}
