import 'package:json_annotation/json_annotation.dart';

part 'companion_word_earn_log_entity.g.dart';

/// Log mỗi khi user học từ → inventory được cộng food
@JsonSerializable()
class CompanionWordEarnLogEntity {
  final int? id;
  final String? userKey;

  /// Số từ đã học trong session này
  final int? wordsLearned;

  /// Số food nhận được từ batch từ này
  final int? foodEarned;

  /// Companion definition tại thời điểm nhận
  final int? definitionId;

  final DateTime? createdAt;

  const CompanionWordEarnLogEntity({
    this.id,
    this.userKey,
    this.wordsLearned,
    this.foodEarned,
    this.definitionId,
    this.createdAt,
  });

  factory CompanionWordEarnLogEntity.fromJson(Map<String, dynamic> json) =>
      _$CompanionWordEarnLogEntityFromJson(json);
  Map<String, dynamic> toJson() => _$CompanionWordEarnLogEntityToJson(this);
}