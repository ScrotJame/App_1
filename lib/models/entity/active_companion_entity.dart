import 'package:json_annotation/json_annotation.dart';
part 'active_companion_entity.g.dart';

@JsonSerializable()
class ActiveCompanionEntity {
  final String? userKey;
  final int? definitionId;
  final int? level;
  final int? totalWordsLearned;
  final int? wordsInCurrentLevel;
  final double? currentXpBonus;
  final bool? isMaxLevel;
  final DateTime? adoptedAt;
  final DateTime? updatedAt;

  const ActiveCompanionEntity({
    this.userKey,
    this.definitionId,
    this.level,
    this.totalWordsLearned,
    this.wordsInCurrentLevel,
    this.currentXpBonus,
    this.isMaxLevel,
    this.adoptedAt,
    this.updatedAt,
  });

  factory ActiveCompanionEntity.fromJson(Map<String, dynamic> json) => _$ActiveCompanionEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveCompanionEntityToJson(this);
}