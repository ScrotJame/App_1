import 'package:json_annotation/json_annotation.dart';

part 'achivement_entity.g.dart';

@JsonSerializable()
class AchivementEntity {
  final String? id;
  final String? code;
  final String? category;
  final String? titleKey;
  final String? descriptionKey;
  final String? iconKey;
  final int? targetValue;
  final int? sortOrder;
  final bool? isVisible;

  // Progress (từ UserAchievementProgressData)
  final int? currentValue;
  final bool? isUnlocked;
  final DateTime? unlockedAt;

  const AchivementEntity({
    this.id,
    this.code,
    this.category,
    this.titleKey,
    this.descriptionKey,
    this.iconKey,
    this.targetValue,
    this.sortOrder,
    this.isVisible = true,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// Tiến trình 0.0 → 1.0, đã clamp, an toàn với targetValue = null/0.
  double get progressPercent {
    final target = targetValue ?? 0;
    if (target <= 0) return 0.0;
    return ((currentValue ?? 0) / target).clamp(0.0, 1.0);
  }

  AchivementEntity copyWith({
    String? id,
    String? code,
    String? category,
    String? titleKey,
    String? descriptionKey,
    String? iconKey,
    int? targetValue,
    int? sortOrder,
    bool? isVisible,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchivementEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      category: category ?? this.category,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      iconKey: iconKey ?? this.iconKey,
      targetValue: targetValue ?? this.targetValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  factory AchivementEntity.fromJson(Map<String, dynamic> json) =>
      _$AchivementEntityFromJson(json);

  Map<String, dynamic> toJson() => _$AchivementEntityToJson(this);
}