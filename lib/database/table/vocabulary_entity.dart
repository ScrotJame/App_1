import 'package:drift/drift.dart';
import 'package:test_abc/database/table/unit_entity.dart';

class VocabularyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text().withLength(min: 1, max: 225)();
  TextColumn get meaning => text()();
  TextColumn get example => text().nullable()();
  TextColumn get pronunciation => text().nullable()();
  TextColumn get language => text().nullable()();

  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();

  BoolColumn get isFavorite => boolean().nullable()();
  DateTimeColumn get lastReviewed => dateTime().nullable()();
  DateTimeColumn get nextReview => dateTime().nullable()();

  IntColumn get unitId => integer()
      .nullable()
      .references(UnitsEntries, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}