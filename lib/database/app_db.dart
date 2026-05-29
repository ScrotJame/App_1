import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:test_abc/database/table/achievement.dart';
import 'package:test_abc/database/table/items.dart';
import 'package:test_abc/database/table/learning_history_log.dart';
import 'package:test_abc/database/table/pet.dart';

import 'package:test_abc/database/table/unit_entity.dart';
import 'package:test_abc/database/table/user.dart';
import 'package:test_abc/database/table/vocabulary_entity.dart';
import 'table/tag_entity.dart';

import 'package:uuid/uuid.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [
  VocabularyEntries, UnitsEntries, Tags, VocabularyTags,
  UsersEntrie, UserActivitiesEntrie, UserWordProgressEntrie,
  ItemsEntrie, UserItemsEntrie,CompanionDefinitions, ActiveCompanions, CompanionFoodLogs, CompanionHistories, CompanionWordEarnLogs,
  LearningHistoryLogs, AchievementDefinitions,UserAchievementProgress
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedItems();
        await _seedTags();
        await seedCompanions();
        await seedAchievement();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _seedTags() async {
    final seedTags = <Insertable<Tag>>[
      TagsCompanion.insert(tagName: 'N5'),
      TagsCompanion.insert(tagName: 'N4'),
      TagsCompanion.insert(tagName: 'N3'),
      TagsCompanion.insert(tagName: 'N2'),
      TagsCompanion.insert(tagName: 'N1'),
      TagsCompanion.insert(tagName: 'Động từ'),
      TagsCompanion.insert(tagName: 'Danh từ'),
      TagsCompanion.insert(tagName: 'Tính từ'),
      TagsCompanion.insert(tagName: 'Chào hỏi'),
    ];await batch((b) => b.insertAll(tags, seedTags));
  }

  Future<void> _seedItems() async {
    final items = <Insertable<ItemsEntrieData>>[
      ItemsEntrieCompanion.insert(
        name: 'Streak Freeze',
        description: Value('Giữ cho chuỗi của bạn không bị mất nếu quên học 1 ngày.'),
        price: 100,
        icon:'IC_FREEZE',
        stock: Value(30)
      ),
      ItemsEntrieCompanion.insert(
          name: 'Test Item',
          description: Value('test'),
          price: 1,
          icon:'IC_FREEZE',
          stock: Value(30)
      ),
      ItemsEntrieCompanion.insert(
        name: 'Double Gems',
        description: Value('Nhận gấp đôi đá quý trong 30 phút tiếp theo.'),
        price: 500,
        icon:'IC_GET_GEMS',
        stock: Value(30)
      ),
      ItemsEntrieCompanion.insert(
        name: 'Save Streal',
        description: Value('Cứu lại streak đã mất'),
        price: 1000,
        icon:'SAVE_STREAK',
        stock: Value(30)
      ),
    ];
    await batch((b) => b.insertAll(itemsEntrie, items));

  }

  Future<void> seedCompanions() async {

    final items = <Insertable<CompanionDefinition>>[
      // ── PET ──────────────────────────────────────────────────
      CompanionDefinitionsCompanion.insert(
        type: 'pet',
        name: 'Mèo Vàng',
        description: 'Mỗi từ học được sẽ cho mèo ăn. Mèo càng lớn, XP càng nhiều.',
        iconKey: '🐱',
        maxXpBonus: const Value(0.20), // +20% XP tối đa
        maxLevel: const Value(10),
        scalingPow: const Value(1.5),
        unlockUserLevel: const Value(1),
      ),
      CompanionDefinitionsCompanion.insert(
        type: 'pet',
        name: 'Chó Trung Thành',
        description: 'Kiên trì theo bạn mỗi ngày. Bonus XP cao nhất trong pets.',
        iconKey: '🐶',
        maxXpBonus: const Value(0.25),
        maxLevel: const Value(10),
        scalingPow: const Value(1.5),
        unlockUserLevel: const Value(1),
      ),
      CompanionDefinitionsCompanion.insert(
        type: 'pet',
        name: 'Cú Trí Tuệ',
        description: 'Thông minh và sâu sắc. Lên cấp chậm hơn nhưng bonus XP vượt trội.',
        iconKey: '🦉',
        maxXpBonus: const Value(0.30),
        maxLevel: const Value(10),
        scalingPow: const Value(1.6),
        unlockUserLevel: const Value(2),
      ),
      CompanionDefinitionsCompanion.insert(
        type: 'pet',
        name: 'Rồng Lửa',
        description: 'Huyền thoại. Cần nhiều từ để lên cấp nhưng sức mạnh không ai sánh bằng.',
        iconKey: '🐉',
        maxXpBonus: const Value(0.40),
        maxLevel: const Value(10),
        scalingPow: const Value(1.8),
        unlockUserLevel: const Value(5),
      ),

      // ── PLANT ────────────────────────────────────────────────
      CompanionDefinitionsCompanion.insert(
        type: 'plant',
        name: 'Mầm Tri Thức',
        description: 'Mỗi từ học là một giọt nước. Từng ngày một, cây lớn dần.',
        iconKey: '🌱',
        maxXpBonus: const Value(0.18),
        maxLevel: const Value(10),
        scalingPow: const Value(1.5),
        unlockUserLevel: const Value(1),
      ),
      CompanionDefinitionsCompanion.insert(
        type: 'plant',
        name: 'Hoa Sakura',
        description: 'Nở rộ theo từng từ bạn học. Đẹp và bonus XP ổn định.',
        iconKey: '🌸',
        maxXpBonus: const Value(0.22),
        maxLevel: const Value(10),
        scalingPow: const Value(1.5),
        unlockUserLevel: const Value(1),
      ),
      CompanionDefinitionsCompanion.insert(
        type: 'plant',
        name: 'Xương Rồng',
        description: 'Không cần nhiều nhưng kiên cường. Phù hợp học viên bền bỉ.',
        iconKey: '🌵',
        maxXpBonus: const Value(0.20),
        maxLevel: const Value(10),
        scalingPow: const Value(1.4),
        unlockUserLevel: const Value(1),
      ),
      CompanionDefinitionsCompanion.insert(
        type: 'plant',
        name: 'Cây Cổ Thụ',
        description: 'Cần hàng trăm từ để trưởng thành. Bonus XP lớn nhất trong plants.',
        iconKey: '🌳',
        maxXpBonus: const Value(0.35),
        maxLevel: const Value(10),
        scalingPow: const Value(1.7),
        unlockUserLevel: const Value(3),
      ),
    ];
    await batch((b) => b.insertAll(companionDefinitions, items));
  }

  Future<void> seedAchievement() async {
    final itemsAchievement = <Insertable<AchievementDefinition>>[
      AchievementDefinitionsCompanion.insert(
        code: 'first_word',
        category: 'milestone',
        titleKey: 'achievement_first_word_title',
        descriptionKey: 'achievement_first_word_desc',
        iconKey: 'ic_achievement_first_word',
        targetValue: 1,
        sortOrder: Value(1),
        isVisible: Value(true),
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'total_10',
        category: 'milestone',
        titleKey: 'achievement_total_10_title',
        descriptionKey: 'achievement_total_10_desc',
        iconKey: 'ic_achievement_total_10',
        targetValue: 10,
        sortOrder: Value(2),
        isVisible: Value(true),
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'total_50',
        category: 'milestone',
        targetValue: 50,
        sortOrder: Value(3),
        isVisible: Value(true),
        titleKey: 'achievement_total_50_title',
        descriptionKey: 'achievement_total_50_desc',
        iconKey: 'ic_achievement_total_50',
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'total_100',
        category: 'milestone',
        targetValue: 100,
        sortOrder: Value(4),
        isVisible: Value(true),
        titleKey: 'achievement_total_100_title',
        descriptionKey: 'achievement_total_100_desc',
        iconKey: 'ic_achievement_total_100',
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'total_500',
        category: 'milestone',
        targetValue: 500,
        sortOrder: Value(5),
        isVisible: Value(true),
        titleKey: 'achievement_total_500_title',
        descriptionKey: 'achievement_total_500_desc',
        iconKey: 'ic_achievement_total_500',
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'total_1000',
        category: 'milestone',
        targetValue: 1000,
        sortOrder: Value(6),
        isVisible: Value(true),
        titleKey: 'achievement_total_1000_title',
        descriptionKey: 'achievement_total_1000_desc',
        iconKey: 'ic_achievement_total_1000',
      ),

      // ── Streak ─────────────────────────────
      AchievementDefinitionsCompanion.insert(
        code: 'streak_3',
        category: 'streak',
        titleKey: 'achievement_streak_3_title',
        descriptionKey: 'achievement_streak_3_desc',
        iconKey: 'ic_achievement_streak_3',
        targetValue: 3,
        sortOrder: Value(10),
        isVisible: Value(true),
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'streak_7',
        category: 'streak',
        targetValue: 7,
        sortOrder: Value(11),
        isVisible: Value(true),
        titleKey: 'achievement_streak_7_title',
        descriptionKey: 'achievement_streak_7_desc',
        iconKey: 'ic_achievement_streak_7',
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'streak_30',
        category: 'streak',
        targetValue: 30,
        sortOrder: Value(12),
        isVisible: Value(true),
        titleKey: 'achievement_streak_30_title',
        descriptionKey: 'achievement_streak_30_desc',
        iconKey: 'ic_achievement_streak_30',
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'streak_100',
        category: 'streak',
        targetValue: 100,
        sortOrder: Value(13),
        isVisible: Value(true),
        titleKey: 'achievement_streak_100_title',
        descriptionKey: 'achievement_streak_100_desc',
        iconKey: 'ic_achievement_streak_100',
      ),

      // ── Collection ─────────────────────────
      AchievementDefinitionsCompanion.insert(
        code: 'complete_unit_1',
        category: 'collection',
        titleKey: 'achievement_complete_unit_title',
        descriptionKey: 'achievement_complete_unit_desc',
        iconKey: 'ic_achievement_unit',
        targetValue: 1,
        sortOrder: Value(20),
        isVisible: Value(true),
      ),
      AchievementDefinitionsCompanion.insert(
        code: 'complete_unit_5',
        category: 'collection',
        targetValue: 5,
        sortOrder: Value(21),
        isVisible: Value(true),
        titleKey: 'achievement_complete_unit_5_title',
        descriptionKey: 'achievement_complete_unit_5_desc',
        iconKey: 'ic_achievement_unit_5',
      ),

      // ── Special ────────────────────────────
      AchievementDefinitionsCompanion.insert(
        code: 'night_owl',
        category: 'special',
        titleKey: 'achievement_night_owl_title',
        descriptionKey: 'achievement_night_owl_desc',
        iconKey: 'ic_achievement_night_owl',
        targetValue: 1,
        sortOrder: Value(30),
        isVisible: Value(false),
      ),
    ];

    await batch(
          (b) => b.insertAll(achievementDefinitions, itemsAchievement),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vocab.db'));
    return NativeDatabase.createInBackground(file);
  });
}