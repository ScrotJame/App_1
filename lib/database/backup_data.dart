import 'package:json_annotation/json_annotation.dart';
import 'package:test_abc/models/entity/companion_word_log_entity.dart';

import '../models/entity/achievement_progress_entity.dart';
import '../models/entity/active_companion_entity.dart';
import '../models/entity/activity_entity.dart';
import '../models/entity/companion_definition_entity.dart';
import '../models/entity/companion_history_entity.dart';
import '../models/entity/item_entity.dart';
import '../models/entity/learning_history_log_entity.dart';
import '../models/entity/tag_entity.dart';
import '../models/entity/unit_entity.dart';
import '../models/entity/user_entity.dart';
import '../models/entity/vocabulary_entity.dart';
import '../models/entity/word_progress_entity.dart';

part 'backup_data.g.dart';

// ─── Root ─────────────────────────────────────────────────────
@JsonSerializable(explicitToJson: true)
class BackupData {
  final int? version;
  final DateTime? exportedAt;
  final String? userKey;
  final UserEntity? user;
  final List<ActivityEntity>? activities;
  final List<WordProgressEntity>? wordProgress;
  final List<UnitEntity>? units;
  final List<VocabularyEntity>? vocabularies;
  final List<TagEntity>? tags;
  final List<VocabularyTagEntity>? vocabularyTags;
  final List<ItemEntity>? items;
  final List<UserItemEntity>? userItems;

  /// The companion catalogue of the exporting device. Only used to match
  /// `definitionId` in [activeCompanion] and [companionHistories] to the
  /// definitions of the importing device; it is never imported itself.
  final List<CompanionDefinitionEntity>? companionDefinitions;
  final ActiveCompanionEntity? activeCompanion;
  final List<CompanionWordLogEntity>? companionWordLogs;
  final List<CompanionHistoryEntity>? companionHistories;

  /// Absent in files written before these were backed up.
  final List<LearningHistoryLogEntity>? learningHistory;
  final List<AchievementProgressEntity>? achievementProgress;

  /// Days with a completed streak, as `yyyy-MM-dd`. Absent in files written
  /// before streak days were backed up.
  final List<String>? streakDates;

  const BackupData({
    this.version,
    this.exportedAt,
    this.userKey,
    this.user,
    this.activities,
    this.wordProgress,
    this.units,
    this.vocabularies,
    this.tags,
    this.vocabularyTags,
    this.items,
    this.userItems,
    this.companionDefinitions,
    this.activeCompanion,
    this.companionWordLogs,
    this.companionHistories,
    this.learningHistory,
    this.achievementProgress,
    this.streakDates,
  });

  factory BackupData.fromJson(Map<String, dynamic> json) => _$BackupDataFromJson(json);
  Map<String, dynamic> toJson() => _$BackupDataToJson(this);
}

// ─── CompanionHistory ──────────────────────────────────────────
