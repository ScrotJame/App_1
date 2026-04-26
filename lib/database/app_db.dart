import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:test_abc/models/unit_entity.dart';
import 'package:test_abc/models/vocabulary_entity.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [VocabularyEntries, UnitsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vocab.db'));
    return NativeDatabase.createInBackground(file);
  });
}