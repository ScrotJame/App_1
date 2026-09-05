import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/ultis/error_utils.dart';
import '../../commons/user_sesion.dart';
import '../../models/items_entity.dart';
import '../../repository/shop_repository.dart';

part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopRepository _repository;
  StreamSubscription<List<ItemsEntity>>? _itemsSub;
  
  final PublishSubject<String> messageController = PublishSubject();

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
      onError: (e) {
        final errMsg = ErrorUtils.networkErrorToMessage(e);
        emit(state.copyWith(
          status: ShopStatus.error,
          errorMessage: errMsg,
        ));
        messageController.sink.add(errMsg);
      },
    );
  }

  // ── Mua item ────────────────────────────────────────────────
  Future<void> purchase(ItemsEntity item) async {
    final stockVal = item.stock ?? 0;
    if (item.stock != null && stockVal <= 0) {
      emit(state.copyWith(
        status: ShopStatus.error,
      ));
      messageController.sink.add('Sản phẩm đã hết hàng');
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
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      emit(state.copyWith(
        status: ShopStatus.error,
      ));
      messageController.sink.add(errMsg);
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
    messageController.close();
    return super.close();
  }
}
