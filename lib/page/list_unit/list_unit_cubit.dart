import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../commons/enums.dart';
import '../../models/unit_entity.dart';
import '../../repository/unit_repository.dart';

part 'list_unit_state.dart';

class ListUnitCubit extends Cubit<ListUnitState> {
  final UnitRepository _repo;

  ListUnitCubit(this._repo) : super(const ListUnitState());

  Future<void> loadUnits() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));
    try {
      final units = await _repo.watchAllUnitsWithWords().first;
      emit(state.copyWith(
        allUnits: units,
        filteredUnits: _applyFilter(units, state.searchQuery, state.sortOrder),
        loadStatus: LOADSTATUS.SUCCESS,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: 'Tải dữ liệu thất bại: $e',
      ));
    }
  }

  void toggleSearch() {
    if (state.isSearching) {
      final filtered =
      _applyFilter(state.allUnits, '', state.sortOrder);
      emit(state.copyWith(
        isSearching: false,
        searchQuery: '',
        filteredUnits: filtered,
      ));
    } else {
      emit(state.copyWith(isSearching: true));
    }
  }

  void onSearchChanged(String query) {
    final filtered =
    _applyFilter(state.allUnits, query, state.sortOrder);
    emit(state.copyWith(searchQuery: query, filteredUnits: filtered));
  }

  void onSortChanged(UnitSortOrder order) {
    final filtered =
    _applyFilter(state.allUnits, state.searchQuery, order);
    emit(state.copyWith(sortOrder: order, filteredUnits: filtered));
  }

  void toggleExpand(int unitId) {
    final current = Set<int>.from(state.expandedUnitIds);
    if (current.contains(unitId)) {
      current.remove(unitId);
    } else {
      current.add(unitId);
    }
    emit(state.copyWith(expandedUnitIds: current));
  }

  void expandAll() {
    final allIds = state.allUnits.map((u) => u.unit.id).toSet();
    emit(state.copyWith(expandedUnitIds: allIds));
  }

  void collapseAll() {
    emit(state.copyWith(expandedUnitIds: {}));
  }

  Future<void> addUnit(String title) async {
    try {
      await _repo.insertUnit(title);
      await loadUnits();
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: 'Thêm unit thất bại: $e',
      ));
    }
  }

  Future<void> updateUnit(int id, String newTitle) async {
    try {
      await _repo.updateUnit(id, newTitle);
      await loadUnits();
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: 'Cập nhật unit thất bại: $e',
      ));
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      await _repo.deleteUnit(id);
      // Xóa khỏi expandedUnitIds nếu có
      final current = Set<int>.from(state.expandedUnitIds)..remove(id);
      emit(state.copyWith(expandedUnitIds: current));
      await loadUnits();
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: 'Xóa unit thất bại: $e',
      ));
    }
  }

  List<UnitWithWords> _applyFilter(
      List<UnitWithWords> units,
      String query,
      UnitSortOrder order,
      ) {
    List<UnitWithWords> result = List.of(units);

    // Search: lọc theo tên unit hoặc từ vựng bên trong
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((u) {
        final matchUnit = u.unit.title.toLowerCase().contains(q);
        final matchWord = u.words.any(
              (w) =>
          w.word.toLowerCase().contains(q) ||
              w.meaning.toLowerCase().contains(q),
        );
        return matchUnit || matchWord;
      }).toList();
    }

    // Sort
    switch (order) {
      case UnitSortOrder.byId:
        result.sort((a, b) => a.unit.id.compareTo(b.unit.id));
        break;
      case UnitSortOrder.byTitle:
        result.sort((a, b) => a.unit.title.compareTo(b.unit.title));
        break;
      case UnitSortOrder.byWordCount:
        result.sort((a, b) => b.words.length.compareTo(a.words.length));
        break;
    }

    return result;
  }
}