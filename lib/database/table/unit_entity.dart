import 'package:drift/drift.dart';

class UnitsEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime).nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)();
}
