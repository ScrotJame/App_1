import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:test_abc/database/table/items.dart';

import 'package:test_abc/database/table/unit_entity.dart';
import 'package:test_abc/database/table/user.dart';
import 'package:test_abc/database/table/vocabulary_entity.dart';
import 'table/tag_entity.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [
  VocabularyEntries, UnitsEntries, Tags, VocabularyTags,
  UsersEntrie, UserActivitiesEntrie, UserWordProgressEntrie,
  ItemsEntrie, UserItemsEntrie,
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
      },
      // Xóa hết onUpgrade vì bắt đầu từ v1
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
        price: 500,
      ),
      ItemsEntrieCompanion.insert(
        name: 'Double Gems',
        description: Value('Nhận gấp đôi đá quý trong 30 phút tiếp theo.'),
        price: 1000,
      ),
      ItemsEntrieCompanion.insert(
        name: 'Save Streal',
        description: Value('Cứu lại streak đã mất'),
        price: 2000,
      ),
    ];
    await batch((b) => b.insertAll(itemsEntrie, items));

  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vocab.db'));
    return NativeDatabase.createInBackground(file);
  });
}