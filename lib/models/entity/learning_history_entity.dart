import 'package:json_annotation/json_annotation.dart';

part 'learning_history_entity.g.dart';

@JsonSerializable()
class LearningHistoryEntity {
  final String? word;
  final String? meaning;
  final int? wordLevelSnapshot;
  final String? sessionType;
  final bool? isCorrect;
  final DateTime? learnedDate;

  const LearningHistoryEntity({
    this.word,
    this.meaning,
    this.wordLevelSnapshot,
    this.sessionType,
    this.isCorrect,
    this.learnedDate,
  });

  LearningHistoryEntity copyWith({
    String? word,
    String? meaning,
    int? wordLevelSnapshot,
    String? sessionType,
    bool? isCorrect,
    DateTime? learnedDate,
  }) {
    return LearningHistoryEntity(
        word: word ?? this.word,
        meaning: meaning ?? this.meaning,
        wordLevelSnapshot: wordLevelSnapshot ?? this.wordLevelSnapshot,
        sessionType: sessionType ?? this.sessionType,
        isCorrect: isCorrect ?? this.isCorrect,
        learnedDate: learnedDate ?? this.learnedDate,
    );
  }

  factory LearningHistoryEntity.fromJson(Map<String, dynamic> json) =>
      _$LearningHistoryEntityFromJson(json);
  Map<String, dynamic> toJson() => _$LearningHistoryEntityToJson(this);
}