import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/commons/enums.dart';

import '../../../commons/user_sesion.dart';
import '../../../models/entity/item_entity.dart';
import '../../../repository/inventory_repository.dart';

part 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;

  InventoryCubit(this._repository) : super(const InventoryState());

  // ─── Load ──────────────────────────────────────────────────────────

  Future<void> loadInventory() async {
    emit(state.copyWith(status: LOADSTATUS.LOADING));
    try {
      final userKey = UserSession.instance.dbUserKey;
      final items   = await _repository.getUserItems(userKey);
      emit(state.copyWith(status: LOADSTATUS.SUCCESS, allItems: items));
    } catch (e) {
      emit(state.copyWith(
        status:       LOADSTATUS.FAILED,
        errorMessage: e.toString(),
      ));
    }
  }

  // ─── Search ────────────────────────────────────────────────────────

  void onSearchChanged(String query) =>
      emit(state.copyWith(searchQuery: query));

  void clearSearch() => emit(state.copyWith(searchQuery: ''));

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> performAction(UserItemEntity userItem) async {
    // TODO: điều phối theo item type, gọi repository tương ứng
    // switch (userItem.item?.actionType) { ... }
  }

  // ─── Refresh ───────────────────────────────────────────────────────

  void refresh() => loadInventory();
}