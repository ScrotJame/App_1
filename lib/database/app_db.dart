import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:test_abc/database/table/items.dart';
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
  ItemsEntrie, UserItemsEntrie,CompanionDefinitions, ActiveCompanions, CompanionWordLogs, CompanionHistories
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
        baseWords: const Value(10),
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
        baseWords: const Value(12),
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
        baseWords: const Value(15),
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
        baseWords: const Value(20),
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
        baseWords: const Value(10),
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
        baseWords: const Value(11),
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
        baseWords: const Value(8),
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
        baseWords: const Value(18),
        scalingPow: const Value(1.7),
        unlockUserLevel: const Value(3),
      ),
    ];
    await batch((b) => b.insertAll(companionDefinitions, items));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vocab.db'));
    return NativeDatabase.createInBackground(file);
  });
}