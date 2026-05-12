import 'package:json_annotation/json_annotation.dart';
part 'tag_entity.g.dart';

@JsonSerializable()
class TagEntity {
  final int? id;
  final String? tagName;
  final String? targetLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TagEntity({
    this.id,
    this.tagName,
    this.targetLanguage,
    this.createdAt,
    this.updatedAt,
  });

  factory TagEntity.fromJson(Map<String, dynamic> json) => _$TagEntityFromJson(json);
  Map<String, dynamic> toJson() => _$TagEntityToJson(this);
}
