import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit() : super(const InventoryState());

  // ─── Load ──────────────────────────────────────────────────────────

  Future<void> loadInventory() async {
    emit(state.copyWith(status: InventoryStatus.loading));
    try {
      // TODO: thay bằng gọi repository thực tế
      await Future.delayed(const Duration(milliseconds: 400));

      // Mock data — xoá khi tích hợp DB
      const mockItems = [
        InventoryItem(
          id: '1',
          name: 'Iron Blade',
          category: ItemCategory.weapon,
          action: 'Equip',
        ),
        InventoryItem(
          id: '2',
          name: 'Star Fruit',
          category: ItemCategory.food,
          action: 'Eat',
        ),
        InventoryItem(
          id: '3',
          name: 'Mana Potion',
          category: ItemCategory.potion,
          action: 'Use',
        ),
        InventoryItem(
          id: '4',
          name: 'Wood Shield',
          category: ItemCategory.armor,
          action: 'Equip',
        ),
        InventoryItem(
          id: '5',
          name: 'Ancient Key',
          category: ItemCategory.quest,
          action: 'Inspect',
        ),
        InventoryItem(
          id: '6',
          name: 'Mystery Egg',
          category: ItemCategory.companion,
          action: 'Hatch',
        ),
      ];

      emit(state.copyWith(
        status: InventoryStatus.loaded,
        allItems: mockItems,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InventoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ─── Filter / Search ───────────────────────────────────────────────

  void selectCategory(ItemCategory category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> performAction(InventoryItem item) async {
    // TODO: xử lý từng action (equip / use / eat / inspect / hatch)
    switch (item.action.toLowerCase()) {
      case 'equip':
        break;
      case 'use':
        break;
      case 'eat':
        break;
      case 'inspect':
        break;
      case 'hatch':
        break;
    }
  }

  void refresh() => loadInventory();
}