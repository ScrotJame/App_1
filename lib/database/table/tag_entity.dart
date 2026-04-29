import 'package:drift/drift.dart';
import 'package:test_abc/database/table/vocabulary_entity.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tagName => text().withLength(min: 1, max: 50)();

  TextColumn get targetLanguage => text().nullable()();
}

class VocabularyTags extends Table {
  IntColumn get wordId => integer()
      .references(VocabularyEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer()
      .references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {wordId, tagId};
}