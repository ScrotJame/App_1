part of 'companion_cubit.dart';

enum CompanionStatus {
  initial,
  loading,

  /// Chưa có companion → hiện màn chọn pet/plant
  awaitingChoice,

  /// Đang xem danh sách companion để chọn
  browsing,

  /// Có companion đang nuôi
  active,

  /// Dialog cảnh báo xóa companion cũ đang mở
  confirmingDelete,

  error,
}

class CompanionState extends Equatable {
  final CompanionStatus status;

  // ── Active companion ────────────────────────────────────────
  final ActiveCompanionEntity? activeCompanion;

  // ── Browsing ────────────────────────────────────────────────
  /// 'pet' | 'plant' | null
  final String? browsingType;
  final List<CompanionDefEntity> availableDefinitions;

  /// Definition đang pending chọn (tap lần 1)
  final int? pendingDefinitionId;

  // ── Level-up feedback ───────────────────────────────────────
  /// Set khi companion vừa lên cấp (để trigger animation)
  final int? justReachedLevel;

  /// Words vừa nạp (để hiện +N animation)
  final int? lastWordsAdded;

  // ── Error ────────────────────────────────────────────────────
  final String? errorMessage;

  const CompanionState({
    this.status = CompanionStatus.initial,
    this.activeCompanion,
    this.browsingType,
    this.availableDefinitions = const [],
    this.pendingDefinitionId,
    this.justReachedLevel,
    this.lastWordsAdded,
    this.errorMessage,
  });

  bool get hasActiveCompanion => activeCompanion != null;
  bool get isMaxLevel => activeCompanion?.isMaxLevel ?? false;

  CompanionState copyWith({
    CompanionStatus? status,
    ActiveCompanionEntity? activeCompanion,
    String? browsingType,
    List<CompanionDefEntity>? availableDefinitions,
    int? pendingDefinitionId,
    int? justReachedLevel,
    int? lastWordsAdded,
    String? errorMessage,
    bool clearActive = false,
    bool clearPending = false,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return CompanionState(
      status: status ?? this.status,
      activeCompanion:
      clearActive ? null : (activeCompanion ?? this.activeCompanion),
      browsingType: browsingType ?? this.browsingType,
      availableDefinitions:
      availableDefinitions ?? this.availableDefinitions,
      pendingDefinitionId:
      clearPending ? null : (pendingDefinitionId ?? this.pendingDefinitionId),
      justReachedLevel:
      clearFeedback ? null : (justReachedLevel ?? this.justReachedLevel),
      lastWordsAdded:
      clearFeedback ? null : (lastWordsAdded ?? this.lastWordsAdded),
      errorMessage:
      clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    activeCompanion,
    browsingType,
    availableDefinitions,
    pendingDefinitionId,
    justReachedLevel,
    lastWordsAdded,
    errorMessage,
  ];
}