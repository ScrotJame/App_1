
import '../database/app_db.dart';

class VocabularyRepository {
  final AppDatabase _db;
  VocabularyRepository(this._db);

  // ─── INSERT ───────────────────────────────────────────────
  Future<int> insertWord(VocabularyEntriesCompanion entry) =>
      _db.into(_db.vocabularyEntries).insert(entry);

  // ─── GET ALL ──────────────────────────────────────────────
  Future<List<VocabularyEntry>> getAllWords() =>
      _db.select(_db.vocabularyEntries).get();

  // ─── WATCH ALL (stream, auto-update UI) ───────────────────
  Stream<List<VocabularyEntry>> watchAllWords() =>
      _db.select(_db.vocabularyEntries).watch();

  // ─── DELETE ───────────────────────────────────────────────
  Future<int> deleteWord(int id) =>
      (_db.delete(_db.vocabularyEntries)
        ..where((t) => t.id.equals(id)))
          .go();

  // ─── UPDATE ───────────────────────────────────────────────
  Future<bool> updateWord(VocabularyEntriesCompanion entry) =>
      _db.update(_db.vocabularyEntries).replace(entry);
}