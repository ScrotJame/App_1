import 'package:json_annotation/json_annotation.dart';
part 'activity_entity.g.dart';

@JsonSerializable()
class ActivityEntity {
  final int? id;
  final String? userKey;
  final DateTime? activityDate;
  final String? note;
  final DateTime? createdAt;

  const ActivityEntity({
    this.id,
    this.userKey,
    this.activityDate,
    this.note,
    this.createdAt,
  });

  factory ActivityEntity.fromJson(Map<String, dynamic> json) => _$ActivityEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityEntityToJson(this);
}