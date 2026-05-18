import 'package:drift/drift.dart';
import 'package:test_abc/database/app_db.dart';

import '../models/unit_entity.dart';

abstract class IUnitRepository {
  Stream<List<UnitWithWords>> watchAllUnitsWithWords();

  Future<int> insertUnit(String title);
  Future<bool> updateUnit(int id, String newTitle, DateTime? createdAt, DateTime updatedAt);
  Future<int> deleteUnit(int id);

  Future<void> addWordToUnit({required int wordId, required int unitId});
  Future<void> removeWordFromUnit({required int wordId});
  Future<List<VocabularyEntry>> getWordsNotInAnyUnit();
}

class UnitRepository implements IUnitRepository {
  final AppDatabase _db;

  UnitRepository(this._db);

  @override
  Stream<List<UnitWithWords>> watchAllUnitsWithWords() {
    final unitsStream = _db.select(_db.unitsEntries).watch();

    return unitsStream.asyncMap((units) async {
      final result = <UnitWithWords>[];

      for (final unit in units) {
        final words = await (_db.select(_db.vocabularyEntries)
          ..where((v) => v.unitId.equals(unit.id)))
            .get();
        result.add(UnitWithWords(unit: unit, words: words));
      }

      return result;
    });
  }

  @override
  Future<int> insertUnit(String title) {
    return _db.into(_db.unitsEntries).insert(
      UnitsEntriesCompanion.insert(title: title),
    );
  }

  @override
  Future<bool> updateUnit(int id, String newTitle, DateTime? createdAt, DateTime updatedAt) {
    return _db.update(_db.unitsEntries).replace(
      UnitsEntry(id: id, title: newTitle, createdAt: createdAt, updatedAt: updatedAt),
    );
  }

  @override
  Future<int> deleteUnit(int id) async {
    await (_db.update(_db.vocabularyEntries)
      ..where((v) => v.unitId.equals(id)))
        .write(const VocabularyEntriesCompanion(unitId: Value(null)));

    return (_db.delete(_db.unitsEntries)
      ..where((u) => u.id.equals(id)))
        .go();
  }

  @override
  Future<void> addWordToUnit({required int wordId, required int unitId}) {
    return (_db.update(_db.vocabularyEntries)
      ..where((v) => v.id.equals(wordId)))
        .write(VocabularyEntriesCompanion(unitId: Value(unitId)));
  }

  @override
  Future<List<VocabularyEntry>> getWordsNotInAnyUnit() {
    return (_db.select(_db.vocabularyEntries)
    ..where((v)=> v.unitId.isNull()))
    .get();
  }

  @override
  Future<void> removeWordFromUnit({required int wordId}) {
    return (_db.update(_db.vocabularyEntries)
      ..where((v)=> v.id.equals(wordId)))
        .write((VocabularyEntriesCompanion(unitId: Value(null)))
    );
  }
}