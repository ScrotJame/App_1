import 'package:json_annotation/json_annotation.dart';
part 'vocabulary_entity.g.dart';

@JsonSerializable()
class VocabularyEntity {
  final int? id;
  final String? word;
  final String? meaning;
  final String? example;
  final String? pronunciation;
  final String? language;
  final int? level;
  final int? correctCount;
  final int? wrongCount;
  final bool? isFavorite;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final int? unitId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VocabularyEntity({
    this.id,
    this.word,
    this.meaning,
    this.example,
    this.pronunciation,
    this.language,
    this.level,
    this.correctCount,
    this.wrongCount,
    this.isFavorite,
    this.lastReviewed,
    this.nextReview,
    this.unitId,
    this.createdAt,
    this.updatedAt,
  });

  factory VocabularyEntity.fromJson(Map<String, dynamic> json) => _$VocabularyEntityFromJson(json);
  Map<String, dynamic> toJson() => _$VocabularyEntityToJson(this);
}

@JsonSerializable()
class VocabularyTagEntity {
  final int? wordId;
  final int? tagId;

  const VocabularyTagEntity({
    this.wordId,
    this.tagId,
  });

  factory VocabularyTagEntity.fromJson(Map<String, dynamic> json) => _$VocabularyTagEntityFromJson(json);
  Map<String, dynamic> toJson() => _$VocabularyTagEntityToJson(this);
}