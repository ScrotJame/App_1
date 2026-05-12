import 'package:json_annotation/json_annotation.dart';

part 'unit_entity.g.dart';

@JsonSerializable()
class UnitEntity {
  final int? id;
  final String? title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UnitEntity({
    this.id,
    this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory UnitEntity.fromJson(Map<String, dynamic> json) => _$UnitEntityFromJson(json);
  Map<String, dynamic> toJson() => _$UnitEntityToJson(this);
}