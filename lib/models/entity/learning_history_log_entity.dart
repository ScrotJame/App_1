import 'package:json_annotation/json_annotation.dart';

part 'learning_history_log_entity.g.dart';

/// One answer from the learning history, as stored in a backup file.
@JsonSerializable()
class LearningHistoryLogEntity {
  /// Id of the word in the same file's `vocabularies` list.
  final int? wordId;
  final int? wordLevelSnapshot;
  final String? sessionType;
  final bool? isCorrect;
  final DateTime? learnedDate;
  final DateTime? createdAt;

  const LearningHistoryLogEntity({
    this.wordId,
    this.wordLevelSnapshot,
    this.sessionType,
    this.isCorrect,
    this.learnedDate,
    this.createdAt,
  });

  factory LearningHistoryLogEntity.fromJson(Map<String, dynamic> json) =>
      _$LearningHistoryLogEntityFromJson(json);
  Map<String, dynamic> toJson() => _$LearningHistoryLogEntityToJson(this);
}
