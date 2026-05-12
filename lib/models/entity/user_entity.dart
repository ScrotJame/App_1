import 'package:json_annotation/json_annotation.dart';
part 'user_entity.g.dart';

@JsonSerializable()
class UserEntity {
  final String? id;
  final String? keyOpen;
  final String? username;
  final String? avatar;
  final int? currentStreak;
  final int? longestStreak;
  final int? totalLearned;
  final DateTime? lastActiveDate;
  final int? gems;
  final int? level;
  final int? experience;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    this.id,
    this.keyOpen,
    this.username,
    this.avatar,
    this.currentStreak,
    this.longestStreak,
    this.totalLearned,
    this.lastActiveDate,
    this.gems,
    this.level,
    this.experience,
    this.createdAt,
    this.updatedAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);
  Map<String, dynamic> toJson() => _$UserEntityToJson(this);
}