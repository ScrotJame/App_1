import 'package:drift/drift.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/database/table/unit_entity.dart';

import '../models/unit_entity.dart';

abstract class IUnitRepository {
  Stream<List<UnitWithWords>> watchAllUnitsWithWords();

  Future<int> insertUnit(String title);
  Future<bool> updateUnit(int id, String newTitle, DateTime? createdAt, DateTime updatedAt);
  Future<int> deleteUnit(int id);

  Future<void> addWordToUnit({required int wordId, required int unitId});
  Future<void> removeWordFromUnit({required int wordId});
  Future<List<VocabularyEntry>> getWordsNotInAnyUnit();

  Future<List<UnitsEntry>> getAllUnits();

  Future<int> addWordsToUnit({
    required int unitId,
    required List<int> wordIds,
  });
}

class UnitRepository implements IUnitRepository {
  final AppDatabase _db;

  UnitRepository(this._db);


  @override
  Stream<List<UnitWithWords>> watchAllUnitsWithWords() {
    try {
      final unitsStream = _db.select(_db.unitsEntries).watch();

      return unitsStream.asyncMap((units) async {
        final result = <UnitWithWords>[];

        for (final unit in units) {
          try {
            final words = await (_db.select(_db.vocabularyEntries)
              ..where((v) => v.unitId.equals(unit.id)))
                .get();
            result.add(UnitWithWords(unit: unit, words: words));
          } catch (e, stackTrace) {
            rethrow;
          }
        }

        return result;
      });
    } catch (e, stackTrace) {
      rethrow;
    }
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

  @override
  Future<List<UnitsEntry>> getAllUnits() =>
      _db.select(_db.unitsEntries).get();

  @override
  Future<int> addWordsToUnit({
    required int unitId,
    required List<int> wordIds,
  }) async {
    if (wordIds.isEmpty) return 0;

    return (_db.update(_db.vocabularyEntries)
      ..where((t) => t.id.isIn(wordIds)))
        .write(VocabularyEntriesCompanion(unitId: Value(unitId)));
  }
}