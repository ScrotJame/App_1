part of 'companion_cubit.dart';

class CompanionState extends Equatable {
  final CompanionStatus status;

  // ── Active companion ─────────────────────────────────────────
  final ActiveCompanionEntity? activeCompanion;

  // ── Browsing ─────────────────────────────────────────────────
  /// 'pet' | 'plant' | null
  final String? browsingType;
  final List<CompanionDefinitionEntity> availableDefinitions;

  /// Definition đang pending chọn (tap lần 1)
  final int? pendingDefinitionId;

  // ── Food feedback ─────────────────────────────────────────────
  /// Set khi companion vừa lên cấp (để trigger animation)
  final int? justReachedLevel;

  /// Số food vừa được earn từ học từ (để hiện "+N food" toast)
  final int? lastFoodEarned;

  /// true ngay sau khi feed thành công (để trigger animation)
  final bool justFed;

  // ── Error ─────────────────────────────────────────────────────
  final String? errorMessage;

  const CompanionState({
    this.status = CompanionStatus.initial,
    this.activeCompanion,
    this.browsingType,
    this.availableDefinitions = const [],
    this.pendingDefinitionId,
    this.justReachedLevel,
    this.lastFoodEarned,
    this.justFed = false,
    this.errorMessage,
  });

  bool get hasActiveCompanion => activeCompanion != null;
  bool get isMaxLevel => activeCompanion?.isMaxLevel ?? false;

  /// Có food trong kho để cho ăn không?
  bool get canFeed =>
      hasActiveCompanion &&
          !isMaxLevel &&
          (activeCompanion!.foodInventory ?? 0) > 0;

  CompanionState copyWith({
    CompanionStatus? status,
    ActiveCompanionEntity? activeCompanion,
    String? browsingType,
    List<CompanionDefinitionEntity>? availableDefinitions,
    int? pendingDefinitionId,
    int? justReachedLevel,
    int? lastFoodEarned,
    bool? justFed,
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
      lastFoodEarned:
      clearFeedback ? null : (lastFoodEarned ?? this.lastFoodEarned),
      justFed: clearFeedback ? false : (justFed ?? this.justFed),
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
    lastFoodEarned,
    justFed,
    errorMessage,
  ];
}