import 'package:drift/drift.dart';
import 'package:test_abc/database/table/vocabulary_entity.dart';

class UsersEntrie extends Table {
  TextColumn get id => text().nullable()();
  TextColumn get keyOpen => text()();
  @override
  Set<Column> get primaryKey => {keyOpen};

  TextColumn get username => text().withLength(min: 3, max: 50)();

  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  IntColumn get totalLearned => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastActiveDate => dateTime().nullable()();

  IntColumn get gems => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get experience => integer().withDefault(const Constant(0))();
}

class UserActivitiesEntrie extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userKey => text().references(UsersEntrie, #keyOpen)();
  DateTimeColumn get activityDate => dateTime()();
  TextColumn get note => text().nullable()();
}

class UserWordProgressEntrie extends Table {
  IntColumn get userId => integer().references(UsersEntrie, #id)();
  IntColumn get wordId => integer().references(VocabularyEntries, #id)();

  // 0: Chưa học, 1: Đang học, 2: Đã thuộc
  IntColumn get status => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastPracticed => dateTime().nullable()();
  DateTimeColumn get nextReview => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {userId, wordId};
}