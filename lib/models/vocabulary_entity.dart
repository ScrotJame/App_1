import 'package:drift/drift.dart';
import 'package:test_abc/models/unit_entity.dart';

// Tên bảng trong DB sẽ là "vocabulary_entries" (Drift tự thêm 's')
class VocabularyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  // late String word -> text()
  TextColumn get word => text().withLength(min: 1, max: 100)();
  TextColumn get meaning => text()();

  // String? -> nullable()
  TextColumn get example => text().nullable()();
  TextColumn get pronunciation => text().nullable()();
  TextColumn get language => text().nullable()();

  // 🔥 Phục vụ học từ (Spaced Repetition)
  // int level = 1 -> integer().withDefault(...)
  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  TextColumn get wordType => text().nullable()();

  BoolColumn get isFavorite => boolean().nullable()();

  // DateTime? -> dateTime().nullable()
  DateTimeColumn get lastReviewed => dateTime().nullable()();
  DateTimeColumn get nextReview => dateTime().nullable()();

  IntColumn get unitId => integer()
      .nullable()
      .references(UnitsEntries, #id, onDelete: KeyAction.cascade)();
}