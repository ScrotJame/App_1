import 'package:json_annotation/json_annotation.dart';

part 'companion_definition_entity.g.dart';

@JsonSerializable()
class CompanionDefinitionEntity {
  final int? id;
  final String? type;
  final String? name;
  final String? description;
  final String? iconKey;
  final double? maxXpBonus;
  final int? maxLevel;

  // ── Food config ──────────────────────────────────────────────
  /// Số food cần để lên 1 cấp (base, tăng dần theo level)
  final int? baseFoodPerLevel;
  final double? scalingPow;

  /// Số từ cần học để nhận 1 food item
  final int? wordsPerFood;

  /// Số food tối đa có thể tích lũy trong inventory
  final int? maxFoodInventory;

  // ── Unlock ───────────────────────────────────────────────────
  final int? unlockUserLevel;

  const CompanionDefinitionEntity({
    this.id,
    this.type,
    this.name,
    this.description,
    this.iconKey,
    this.maxXpBonus,
    this.maxLevel,
    this.baseFoodPerLevel,
    this.scalingPow,
    this.wordsPerFood,
    this.maxFoodInventory,
    this.unlockUserLevel,
  });

  /// Label icon food theo loại companion
  String get foodIcon => type == 'plant' ? '💧' : '🍖';
  String get feedVerb => type == 'plant' ? 'Tưới cây' : 'Cho ăn';

  /// Tính số food cần để lên cấp [level]
  int foodNeededForLevel(int level) {
    final base = baseFoodPerLevel ?? 5;
    final pow = scalingPow ?? 1.5;
    double result = 1.0;
    for (int i = 0; i < level; i++) {
      result *= pow;
    }
    return (base * result).ceil();
  }

  factory CompanionDefinitionEntity.fromJson(Map<String, dynamic> json) =>
      _$CompanionDefinitionEntityFromJson(json);
  Map<String, dynamic> toJson() => _$CompanionDefinitionEntityToJson(this);
}