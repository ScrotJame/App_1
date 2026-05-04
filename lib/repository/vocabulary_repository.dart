import 'package:drift/drift.dart';
import '../database/app_db.dart';
import '../models/tag_vocab.dart';

abstract class IVocabularyRepository {
  Future<int> insertWord({
    required String word,
    required String meaning,
    String? pronunciation,
  });

  Future<List<VocabularyEntry>> getAllWords();

  Stream<List<VocabularyEntry>> watchAllWords();

  Stream<List<VocabularyWithTags>> watchAllWordsWithTags();

  Future<int> deleteWord(int id);

  Future<bool> updateWord({
    required int id,
    required String word,
    required String meaning,
    String? pronunciation,
  });

  // tag
  Future<void> attachTag({required int wordId, required int tagId});
  Future<void> detachTag({required int wordId, required int tagId});
  Future<void> detachAllTags({required int wordId});
  Future<List<int>> getTagIdsByWordId(int wordId);
  Future<VocabularyEntry?> incrementWordLevel(int id);
}

class VocabularyRepository implements IVocabularyRepository {
  final AppDatabase _db;
  VocabularyRepository(this._db);

  @override
  Future<int> insertWord({
    required String word,
    required String meaning,
    String? pronunciation,
  }) =>
      _db.into(_db.vocabularyEntries).insert(
        VocabularyEntriesCompanion.insert(
          word: word,
          meaning: meaning,
          pronunciation: pronunciation != null
              ? Value(pronunciation)
              : const Value.absent(),
        ),
      );

  @override
  Future<List<VocabularyEntry>> getAllWords() =>
      _db.select(_db.vocabularyEntries).get();

  @override
  Stream<List<VocabularyEntry>> watchAllWords() =>
      _db.select(_db.vocabularyEntries).watch();

  @override
  Stream<List<VocabularyWithTags>> watchAllWordsWithTags() {
    return _db.select(_db.vocabularyEntries).watch().asyncMap((words) async {
      return Future.wait(words.map((word) async {
        final tagLinks = await (_db.select(_db.vocabularyTags)
          ..where((t) => t.wordId.equals(word.id)))
            .get();

        if (tagLinks.isEmpty) {
          return VocabularyWithTags(word: word, tags: const []);
        }

        final tagIds = tagLinks.map((t) => t.tagId).toList();

        final tags = await (_db.select(_db.tags)
          ..where((t) => t.id.isIn(tagIds)))
            .get();

        return VocabularyWithTags(word: word, tags: tags);
      }));
    });
  }

  @override
  Future<int> deleteWord(int id) =>
      (_db.delete(_db.vocabularyEntries)..where((t) => t.id.equals(id))).go();

  @override
  Future<bool> updateWord({
    required int id,
    required String word,
    required String meaning,
    String? pronunciation,
  }) =>
      _db.update(_db.vocabularyEntries).replace(
        VocabularyEntriesCompanion(
          id: Value(id),
          word: Value(word),
          meaning: Value(meaning),
          pronunciation: pronunciation != null
              ? Value(pronunciation)
              : const Value.absent(),
        ),
      );

  @override
  Future<void> attachTag({required int wordId, required int tagId}) =>
      _db.into(_db.vocabularyTags).insert(
        VocabularyTagsCompanion.insert(wordId: wordId, tagId: tagId),
        mode: InsertMode.insertOrIgnore, // tránh duplicate
      );

  @override
  Future<void> detachTag({required int wordId, required int tagId}) =>
      (_db.delete(_db.vocabularyTags)
        ..where((t) => t.wordId.equals(wordId) & t.tagId.equals(tagId)))
          .go();

  // Xóa toàn bộ tag của 1 từ — dùng trước khi gắn lại khi update
  @override
  Future<void> detachAllTags({required int wordId}) =>
      (_db.delete(_db.vocabularyTags)
        ..where((t) => t.wordId.equals(wordId)))
          .go();

  // Lấy danh sách tagId đang gắn với 1 từ — dùng khi vào edit mode
  @override
  Future<List<int>> getTagIdsByWordId(int wordId) async {
    final rows = await (_db.select(_db.vocabularyTags)
      ..where((t) => t.wordId.equals(wordId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }

  @override
  Future<VocabularyEntry?> incrementWordLevel(int id) async {
    final word = await (_db.select(_db.vocabularyEntries)
      ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (word == null) return null;

    final newLevel = (word.level) + 1;

    await (_db.update(_db.vocabularyEntries)
      ..where((t) => t.id.equals(id)))
        .write(VocabularyEntriesCompanion(level: Value(newLevel)));

    // Trả về bản ghi mới nhất từ DB
    return (_db.select(_db.vocabularyEntries)
      ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}