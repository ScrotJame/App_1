import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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

  // ── Init ─────────────────────────────────────────────────────

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

        // Detect level-up
        final prevLevel = state.activeCompanion?.level ?? 0;
        final justLeveledUp = active.level > prevLevel && prevLevel > 0;

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

  // ── Browse type ──────────────────────────────────────────────

  /// User chọn tab 'pet' hoặc 'plant'
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

  /// Quay lại màn chọn loại (chỉ khi chưa có companion)
  void backToTypeChoice() {
    if (state.hasActiveCompanion) return;
    emit(state.copyWith(
      status: CompanionStatus.awaitingChoice,
      browsingType: null,
      availableDefinitions: const [],
      clearPending: true,
    ));
  }

  // ── Pending / Confirm ────────────────────────────────────────

  /// Tap vào một companion card → set pending
  void setPending(int definitionId) {
    if (state.pendingDefinitionId == definitionId) return;
    emit(state.copyWith(pendingDefinitionId: definitionId));
  }

  void clearPending() {
    emit(state.copyWith(clearPending: true));
  }

  /// Xác nhận adopt — không có companion cũ
  Future<void> confirmAdopt() async {
    final defId = state.pendingDefinitionId;
    if (defId == null) return;

    emit(state.copyWith(status: CompanionStatus.loading));
    try {
      await _repo.adoptCompanion(userKey: _userKey, definitionId: defId);
      // Stream sẽ tự update status → active
    } catch (e) {
      emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Switch companion (có companion cũ → dialog xác nhận) ─────

  /// Gọi khi user đang có companion và muốn chọn cái mới.
  /// UI phải hiện Dialog trước khi gọi confirmSwitch().
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

  /// Thực sự xóa companion cũ và nhận con mới
  Future<void> confirmSwitch() async {
    final defId = state.pendingDefinitionId;
    if (defId == null) return;

    emit(state.copyWith(status: CompanionStatus.loading));
    try {
      await _repo.switchCompanion(
        userKey: _userKey,
        newDefinitionId: defId,
      );
      // Stream sẽ tự update
    } catch (e) {
      emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Feed words ───────────────────────────────────────────────

  /// Gọi sau mỗi phiên học — [wordsCount] = số từ user vừa học được.
  /// Companion sẽ nhận thức ăn/nước và có thể lên cấp.
  Future<void> feedWords(int wordsCount) async {
    if (!state.hasActiveCompanion || wordsCount <= 0) return;
    try {
      await _repo.feedWords(
        userKey: _userKey,
        wordsCount: wordsCount,
      );
      emit(state.copyWith(lastWordsAdded: wordsCount));
      // level-up được detect tự động qua stream so sánh level
    } catch (e) {
      emit(state.copyWith(
        status: CompanionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true, clearError: true));
  }

  @override
  Future<void> close() {
    _activeSub?.cancel();
    return super.close();
  }
}