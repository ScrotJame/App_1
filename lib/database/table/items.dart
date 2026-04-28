import 'package:drift/drift.dart';
import 'package:test_abc/database/table/user.dart';

class ItemsEntrie extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get price => integer()();
}

class UserItemsEntrie extends Table {
  IntColumn get userId => integer().references(UsersEntrie, #id)();
  IntColumn get itemId => integer().references(ItemsEntrie, #id)();

  // Số lượng vật phẩm người dùng đang có
  IntColumn get quantity => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId, itemId};
}