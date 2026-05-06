import 'package:json_annotation/json_annotation.dart';

part 'backup_data.g.dart';

// ─── Root ─────────────────────────────────────────────────────
@JsonSerializable(explicitToJson: true)
class BackupData {
  final int version;
  final DateTime exportedAt;
  final String userKey;
  final BackupUser user;
  final List<BackupActivity> activities;
  final List<BackupWordProgress> wordProgress;
  final List<BackupUnit> units;
  final List<BackupVocabulary> vocabularies;
  final List<BackupTag> tags;
  final List<BackupVocabularyTag> vocabularyTags;
  final List<BackupUserItem> userItems;

  const BackupData({
    required this.version,
    required this.exportedAt,
    required this.userKey,
    required this.user,
    required this.activities,
    required this.wordProgress,
    required this.units,
    required this.vocabularies,
    required this.tags,
    required this.vocabularyTags,
    required this.userItems,
  });

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);

  Map<String, dynamic> toJson() => _$BackupDataToJson(this);
}

@JsonSerializable()
class BackupUser {
  final String? id;
  final String keyOpen;
  final String username;
  final int currentStreak;
  final int longestStreak;
  final int totalLearned;
  final DateTime? lastActiveDate;
  final int gems;
  final int level;
  final int experience;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BackupUser({
    this.id,
    required this.keyOpen,
    required this.username,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalLearned,
    this.lastActiveDate,
    required this.gems,
    required this.level,
    required this.experience,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackupUser.fromJson(Map<String, dynamic> json) =>
      _$BackupUserFromJson(json);

  Map<String, dynamic> toJson() => _$BackupUserToJson(this);
}

@JsonSerializable()
class BackupActivity {
  final int id;
  final String userKey;
  final DateTime activityDate;
  final String? note;
  final DateTime createdAt;

  const BackupActivity({
    required this.id,
    required this.userKey,
    required this.activityDate,
    this.note,
    required this.createdAt,
  });

  factory BackupActivity.fromJson(Map<String, dynamic> json) =>
      _$BackupActivityFromJson(json);

  Map<String, dynamic> toJson() => _$BackupActivityToJson(this);
}

@JsonSerializable()
class BackupWordProgress {
  final String userId;
  final int wordId;
  final int status;
  final DateTime? lastPracticed;
  final DateTime? nextReview;
  final DateTime updatedAt;

  const BackupWordProgress({
    required this.userId,
    required this.wordId,
    required this.status,
    this.lastPracticed,
    this.nextReview,
    required this.updatedAt,
  });

  factory BackupWordProgress.fromJson(Map<String, dynamic> json) =>
      _$BackupWordProgressFromJson(json);

  Map<String, dynamic> toJson() => _$BackupWordProgressToJson(this);
}

@JsonSerializable()
class BackupUnit {
  final int id;
  final String title;
  final DateTime? createdAt;
  final DateTime updatedAt;

  const BackupUnit({
    required this.id,
    required this.title,
    this.createdAt,
    required this.updatedAt,
  });

  factory BackupUnit.fromJson(Map<String, dynamic> json) =>
      _$BackupUnitFromJson(json);

  Map<String, dynamic> toJson() => _$BackupUnitToJson(this);
}

@JsonSerializable()
class BackupVocabulary {
  final int id;
  final String word;
  final String meaning;
  final String? example;
  final String? pronunciation;
  final String? language;
  final int level;
  final int correctCount;
  final int wrongCount;
  final bool? isFavorite;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final int? unitId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BackupVocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    this.example,
    this.pronunciation,
    this.language,
    required this.level,
    required this.correctCount,
    required this.wrongCount,
    this.isFavorite,
    this.lastReviewed,
    this.nextReview,
    this.unitId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackupVocabulary.fromJson(Map<String, dynamic> json) =>
      _$BackupVocabularyFromJson(json);

  Map<String, dynamic> toJson() => _$BackupVocabularyToJson(this);
}

@JsonSerializable()
class BackupTag {
  final int id;
  final String tagName;
  final String? targetLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BackupTag({
    required this.id,
    required this.tagName,
    this.targetLanguage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackupTag.fromJson(Map<String, dynamic> json) =>
      _$BackupTagFromJson(json);

  Map<String, dynamic> toJson() => _$BackupTagToJson(this);
}

@JsonSerializable()
class BackupVocabularyTag {
  final int wordId;
  final int tagId;

  const BackupVocabularyTag({
    required this.wordId,
    required this.tagId,
  });

  factory BackupVocabularyTag.fromJson(Map<String, dynamic> json) =>
      _$BackupVocabularyTagFromJson(json);

  Map<String, dynamic> toJson() => _$BackupVocabularyTagToJson(this);
}

@JsonSerializable()
class BackupUserItem {
  final String userId;
  final int itemId;
  final int quantity;

  const BackupUserItem({
    required this.userId,
    required this.itemId,
    required this.quantity,
  });

  factory BackupUserItem.fromJson(Map<String, dynamic> json) =>
      _$BackupUserItemFromJson(json);

  Map<String, dynamic> toJson() => _$BackupUserItemToJson(this);
}