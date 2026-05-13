import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../commons/user_sesion.dart';
import '../../models/items_entity.dart';
import '../../repository/shop_repository.dart';
import '../user/inventory/inventory_cubit.dart';

part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopRepository _repository;
  StreamSubscription<List<ItemsEntity>>? _itemsSub;

  ShopCubit(this._repository) : super(const ShopState()) {
    _watchItems();
  }

  // ── Lắng nghe stream items từ DB ────────────────────────────
  void _watchItems() {
    emit(state.copyWith(status: ShopStatus.loading));
    _itemsSub = _repository.watchProducts().listen(
          (items) => emit(state.copyWith(
        status: ShopStatus.initial,
        items: items,
      )),
      onError: (e) => emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: " tesst ${e.toString()}",
      )),
    );
  }

  // ── Mua item ────────────────────────────────────────────────
  Future<void> purchase(ItemsEntity item) async {
    if (item.stock != null && item.stock! <= 0) {
      emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: 'Sản phẩm đã hết hàng',
      ));
      return;
    }

    emit(state.copyWith(
      status: ShopStatus.loading,
      purchasedItemId: item.id,
    ));

    try {
      final userId = UserSession.instance.dbUserKey;

      await _repository.buyProduct(item, userId);

      emit(state.copyWith(
        status: ShopStatus.success,
        purchasedItemId: item.id,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ShopStatus.error,
        errorMessage: e.toString(), // lỗi từ repo (hết hàng, không tìm thấy,…)
      ));
    }
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }
  void reset() => emit(state.copyWith(
    status: ShopStatus.initial,
    purchasedItemId: null,
    errorMessage: null,
  ));

  @override
  Future<void> close() {
    _itemsSub?.cancel();
    return super.close();
  }
}