import 'package:json_annotation/json_annotation.dart';
part 'companion_history_entity.g.dart';

@JsonSerializable()
class CompanionHistoryEntity {
  final int? id;
  final String? userKey;
  final int? definitionId;
  final int? levelReached;
  final int? totalWordsLearned;
  final DateTime? adoptedAt;
  final DateTime? deletedAt;

  const CompanionHistoryEntity({
    this.id,
    this.userKey,
    this.definitionId,
    this.levelReached,
    this.totalWordsLearned,
    this.adoptedAt,
    this.deletedAt,
  });

  factory CompanionHistoryEntity.fromJson(Map<String, dynamic> json) => _$CompanionHistoryEntityFromJson(json);
  Map<String, dynamic> toJson() => _$CompanionHistoryEntityToJson(this);
}