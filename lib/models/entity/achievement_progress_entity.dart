import 'package:json_annotation/json_annotation.dart';

part 'achievement_progress_entity.g.dart';

/// A user's progress on one achievement, as stored in a backup file.
@JsonSerializable()
class AchievementProgressEntity {
  /// `AchievementDefinitions.code`. Definition ids are generated per install,
  /// so the code is the only identity that is the same on every device.
  final String? code;
  final int? currentValue;
  final bool? isUnlocked;
  final DateTime? unlockedAt;
  final DateTime? updatedAt;

  const AchievementProgressEntity({
    this.code,
    this.currentValue,
    this.isUnlocked,
    this.unlockedAt,
    this.updatedAt,
  });

  factory AchievementProgressEntity.fromJson(Map<String, dynamic> json) =>
      _$AchievementProgressEntityFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementProgressEntityToJson(this);
}
