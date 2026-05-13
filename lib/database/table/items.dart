import 'package:drift/drift.dart';
import 'package:test_abc/database/table/user.dart';
import 'package:uuid/uuid.dart';

class ItemsEntrie extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get icon => text().withLength(min: 1, max: 500)();
  RealColumn get price => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class UserItemsEntrie extends Table {
  TextColumn get userId => text().references(UsersEntrie, #keyOpen)();
  TextColumn get itemId => text().references(ItemsEntrie, #id)();

  // Số lượng vật phẩm người dùng đang có
  IntColumn get quantity => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId, itemId};
}