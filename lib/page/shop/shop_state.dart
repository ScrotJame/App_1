part of 'shop_cubit.dart';

enum ShopStatus { initial, loading, success, error }

class ShopState extends Equatable {
  final ShopStatus status;
  final List<ItemsEntity> items;
  final String? purchasedItemId;   // id của item vừa mua (thay DealTier)
  final String? errorMessage;

  const ShopState({
    this.status = ShopStatus.initial,
    this.items = const [],
    this.purchasedItemId,
    this.errorMessage,
  });

  ShopState copyWith({
    ShopStatus? status,
    List<ItemsEntity>? items,
    String? purchasedItemId,
    String? errorMessage,
  }) {
    return ShopState(
      status: status ?? this.status,
      items: items ?? this.items,
      purchasedItemId: purchasedItemId ?? this.purchasedItemId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, purchasedItemId, errorMessage];
}