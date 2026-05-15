import 'package:json_annotation/json_annotation.dart';
part 'companion_word_log_entity.g.dart';
@JsonSerializable()
class CompanionWordLogEntity {
  final int? id;
  final String? userKey;
  final int? foodUsed;
  final int? levelAtTime;
  final int? definitionId;
  final bool? causedLevelUp;
  final DateTime? createdAt;

  const CompanionWordLogEntity({
    this.id,
    this.userKey,
    this.foodUsed,
    this.levelAtTime,
    this.definitionId,
    this.causedLevelUp,
    this.createdAt,
  });

  factory CompanionWordLogEntity.fromJson(Map<String, dynamic> json) => _$CompanionWordLogEntityFromJson(json);
  Map<String, dynamic> toJson() => _$CompanionWordLogEntityToJson(this);
}