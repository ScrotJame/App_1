import 'package:drift/drift.dart';
import 'package:test_abc/database/table/user.dart';
import 'package:test_abc/database/table/vocabulary_entity.dart';

class LearningHistoryLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userKey =>
      text().references(UsersEntrie, #keyOpen)();

  IntColumn get wordId =>
      integer().references(VocabularyEntries, #id,
          onDelete: KeyAction.cascade)();

  IntColumn get wordLevelSnapshot => integer()();

  TextColumn get sessionType => text()();

  BoolColumn get isCorrect =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get learnedDate => dateTime()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}