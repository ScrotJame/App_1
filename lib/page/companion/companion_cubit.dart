import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../commons/enums.dart';
import '../../models/entity/active_companion_entity.dart';
import '../../models/entity/companion_definition_entity.dart';
import '../../repository/companion_repository.dart';

part 'companion_state.dart';

class CompanionCubit extends Cubit<CompanionState> {
  final CompanionRepository _repo;
  final String _userKey;
  StreamSubscription<ActiveCompanionEntity?>? _activeSub;

  CompanionCubit({
    required CompanionRepository repository,
    required String userKey,
  })  : _repo = repository,
        _userKey = userKey,
        super(const CompanionState()) {
    _init();
  }

  // ── Init ──────────────────────────────────────────────────────

  void _init() {
    emit(state.copyWith(status: CompanionStatus.loading));

    _activeSub = _repo.watchActiveCompanion(_userKey).listen(
          (active) {
        if (active == null) {
          emit(state.copyWith(
            status: CompanionStatus.awaitingChoice,
            clearActive: true,
          ));
          return;
        }

        // Detect level-up qua stream
        final prevLevel = state.activeCompanion?.level ?? 0;
        final justLeveledUp =
            (active.level ?? 0) > prevLevel && prevLevel > 0;

        emit(state.copyWith(
          status: CompanionStatus.active,
          activeCompanion: active,
          justReachedLevel: justLeveledUp ? active.level : null,
        ));
      },
      onError: (e) => emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      )),
    );
  }

  // ── Browse type ───────────────────────────────────────────────

  Future<void> browseType(String type) async {
    assert(type == 'pet' || type == 'plant');
    emit(state.copyWith(
      status: CompanionStatus.loading,
      browsingType: type,
    ));
    try {
      final defs = await _repo.getDefinitionsByType(type);
      emit(state.copyWith(
        status: CompanionStatus.browsing,
        availableDefinitions: defs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void backToTypeChoice() {
    if (state.hasActiveCompanion) return;
    emit(state.copyWith(
      status: CompanionStatus.awaitingChoice,
      browsingType: null,
      availableDefinitions: const [],
      clearPending: true,
    ));
  }

  // ── Pending / Confirm ─────────────────────────────────────────

  void setPending(int definitionId) {
    if (state.pendingDefinitionId == definitionId) return;
    emit(state.copyWith(pendingDefinitionId: definitionId));
  }

  void clearPending() => emit(state.copyWith(clearPending: true));

  Future<void> confirmAdopt() async {
    final defId = state.pendingDefinitionId;
    if (defId == null) return;

    emit(state.copyWith(status: CompanionStatus.loading));
    try {
      await _repo.adoptCompanion(userKey: _userKey, definitionId: defId);
    } catch (e) {
      emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Switch companion ──────────────────────────────────────────

  void requestSwitch(int newDefinitionId) {
    emit(state.copyWith(
      status: CompanionStatus.confirmingDelete,
      pendingDefinitionId: newDefinitionId,
    ));
  }

  void cancelSwitch() {
    emit(state.copyWith(
      status: CompanionStatus.active,
      clearPending: true,
    ));
  }

  Future<void> confirmSwitch() async {
    final defId = state.pendingDefinitionId;
    if (defId == null) return;

    emit(state.copyWith(status: CompanionStatus.loading));
    try {
      await _repo.switchCompanion(
        userKey: _userKey,
        newDefinitionId: defId,
      );
    } catch (e) {
      emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }



  // ── Feed companion (gọi khi user tap nút) ────────────────────

  /// User tap "Cho ăn / Tưới cây":
  ///   - Lấy 1 food từ inventory
  ///   - Tăng foodUsedInCurrentLevel
  ///   - Nếu đủ → lên cấp (stream sẽ detect)
  Future<void> feedCompanion() async {
    if (!state.canFeed) return;

    try {
      await _repo.feedCompanion(userKey: _userKey);
      emit(state.copyWith(justFed: true));
      // Level-up detect tự động qua stream so sánh level
    } catch (e) {
      emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true, clearError: true));
  }

  @override
  Future<void> close() {
    _activeSub?.cancel();
    return super.close();
  }
}
