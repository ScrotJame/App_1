import 'package:json_annotation/json_annotation.dart';

part 'word_progress_entity.g.dart';

@JsonSerializable()
class WordProgressEntity {
  final String? userId;
  final int? wordId;
  final int? status;
  final DateTime? lastPracticed;
  final DateTime? nextReview;
  final DateTime? updatedAt;

  const WordProgressEntity({
    this.userId,
    this.wordId,
    this.status,
    this.lastPracticed,
    this.nextReview,
    this.updatedAt,
  });

  factory WordProgressEntity.fromJson(Map<String, dynamic> json) => _$WordProgressEntityFromJson(json);
  Map<String, dynamic> toJson() => _$WordProgressEntityToJson(this);
}