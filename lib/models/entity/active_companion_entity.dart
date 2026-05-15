import 'package:json_annotation/json_annotation.dart';
import 'companion_definition_entity.dart';

part 'active_companion_entity.g.dart';

@JsonSerializable()
class ActiveCompanionEntity {
  final String? userKey;
  final int? definitionId;
  final int? level;

  // ── Food inventory ───────────────────────────────────────────
  /// Số food/water item đang có trong kho
  final int? foodInventory;

  /// Phần dư từ chưa đủ để đổi thành food
  final double? pendingWords;

  // ── Progression ──────────────────────────────────────────────
  /// Số food đã dùng trong cấp hiện tại (tiến trình lên cấp)
  final int? foodUsedInCurrentLevel;

  /// Tổng food đã dùng từ khi adopt
  final int? totalFoodUsed;

  /// Tổng từ đã học từ khi adopt (thống kê)
  final double? totalWordsLearned;

  // ── XP bonus ─────────────────────────────────────────────────
  final double? currentXpBonus;
  final bool? isMaxLevel;

  final DateTime? adoptedAt;
  final DateTime? updatedAt;

  // ── Joined definition (optional, không lưu DB) ───────────────
  @JsonKey(includeFromJson: false, includeToJson: false)
  final CompanionDefinitionEntity? definition;

  const ActiveCompanionEntity({
    this.userKey,
    this.definitionId,
    this.level,
    this.foodInventory,
    this.pendingWords,
    this.foodUsedInCurrentLevel,
    this.totalFoodUsed,
    this.totalWordsLearned,
    this.currentXpBonus,
    this.isMaxLevel,
    this.adoptedAt,
    this.updatedAt,
    this.definition,
  });

  // ── Computed helpers ─────────────────────────────────────────

  /// Tên hiển thị (fallback về definition name)
  String get displayName => definition?.name ?? 'Companion';

  /// Số food cần để lên cấp tiếp theo
  /// foodNeeded(level) = (baseFoodPerLevel * level^scalingPow).ceil()
  int get foodNeededForNextLevel {
    if (definition == null || isMaxLevel == true) return 0;
    final base = definition!.baseFoodPerLevel ?? 5;
    final pow = definition!.scalingPow ?? 1.5;
    final lv = level ?? 1;
    return (base * _pow(lv, pow)).ceil();
  }

  /// Tiến trình lên cấp (0.0 → 1.0)
  double get levelProgress {
    final needed = foodNeededForNextLevel;
    if (needed == 0) return 1.0;
    return ((foodUsedInCurrentLevel ?? 0) / needed).clamp(0.0, 1.0);
  }

  /// Inventory có đầy không?
  bool get isFoodFull {
    final cap = definition?.maxFoodInventory ?? 10;
    return (foodInventory ?? 0) >= cap;
  }

  /// Inventory hiện tại / tối đa
  String get foodInventoryLabel {
    final cap = definition?.maxFoodInventory ?? 10;
    return '${foodInventory ?? 0} / $cap';
  }

  /// Số từ cần để nhận thêm 1 food
  num get wordsUntilNextFood {
    final wpf = definition?.wordsPerFood ?? 10;
    final pending = pendingWords ?? 0;
    return (wpf - pending).clamp(0, wpf);
  }

  static double _pow(int base, double exp) {
    double result = 1.0;
    for (int i = 0; i < base; i++) {
      result *= exp;
    }
    // dart:math pow is fine, but keeping zero-dependency here
    // In real code use: import 'dart:math'; return math.pow(base, exp).toDouble();
    return result;
  }

  ActiveCompanionEntity copyWith({
    String? userKey,
    int? definitionId,
    int? level,
    int? foodInventory,
    double? pendingWords,
    int? foodUsedInCurrentLevel,
    int? totalFoodUsed,
    double? totalWordsLearned,
    double? currentXpBonus,
    bool? isMaxLevel,
    DateTime? adoptedAt,
    DateTime? updatedAt,
    CompanionDefinitionEntity? definition,
  }) {
    return ActiveCompanionEntity(
      userKey: userKey ?? this.userKey,
      definitionId: definitionId ?? this.definitionId,
      level: level ?? this.level,
      foodInventory: foodInventory ?? this.foodInventory,
      pendingWords: pendingWords ?? this.pendingWords,
      foodUsedInCurrentLevel: foodUsedInCurrentLevel ?? this.foodUsedInCurrentLevel,
      totalFoodUsed: totalFoodUsed ?? this.totalFoodUsed,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      currentXpBonus: currentXpBonus ?? this.currentXpBonus,
      isMaxLevel: isMaxLevel ?? this.isMaxLevel,
      adoptedAt: adoptedAt ?? this.adoptedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      definition: definition ?? this.definition,
    );
  }

  factory ActiveCompanionEntity.fromJson(Map<String, dynamic> json) =>
      _$ActiveCompanionEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveCompanionEntityToJson(this);
}