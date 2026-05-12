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
  final int? baseWords;
  final double? scalingPow;
  final int? unlockUserLevel;

  const CompanionDefinitionEntity({
    this.id,
    this.type,
    this.name,
    this.description,
    this.iconKey,
    this.maxXpBonus,
    this.maxLevel,
    this.baseWords,
    this.scalingPow,
    this.unlockUserLevel,
  });

  factory CompanionDefinitionEntity.fromJson(Map<String, dynamic> json) => _$CompanionDefinitionEntityFromJson(json);
  Map<String, dynamic> toJson() => _$CompanionDefinitionEntityToJson(this);
}