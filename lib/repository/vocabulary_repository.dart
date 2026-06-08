import 'package:drift/drift.dart';
import '../commons/status_comon.dart';
import '../database/app_db.dart';
import '../models/tag_vocab.dart';

abstract class IVocabularyRepository {
  Future<int> insertWord({
    required String word,
    required String meaning,
    String? pronunciation,
    String? language,
  });

  Future<List<VocabularyEntry>> getAllWords();

  Stream<List<VocabularyEntry>> watchAllWords();

  Stream<List<VocabularyWithTags>> watchAllWordsWithTags();

  Future<int> deleteWord(int id);

  Future<int> deleteWords(List<int> ids);

  Future<bool> updateWord({
    required int id,
    required String word,
    required String meaning,
    String? pronunciation,
    String? language,
  });

  // tag
  Future<void> attachTag({required int wordId, required int tagId});
  Future<void> detachTag({required int wordId, required int tagId});
  Future<void> detachAllTags({required int wordId});
  Future<List<int>> getTagIdsByWordId(int wordId);
  Future<VocabularyEntry?> incrementWordLevel(int id);
  Future<void> changeWordState(int wordId, int newLevel, String? userId);
  Future<void> countWordLearn( String userId);
  Future<bool> isWordAlreadyMastered(int wordId, String userId);

  Future<void> updateWordSM2Progress({
    required int wordId,
    required double easeFactor,
    required int repetitions,
    required int interval,
    required DateTime nextReview,
  });

  Future<void> getLanguageTags();
  Future<List<VocabularyEntry>> getWordsByLanguageTags(String? tags);
}

class VocabularyRepository implements IVocabularyRepository {
  final AppDatabase _db;
  VocabularyRepository(this._db);

  @override
  Future<int> insertWord({
    required String word,
    required String meaning,
    String? pronunciation,
    String? language,
  }) =>
      _db.into(_db.vocabularyEntries).insert(
        VocabularyEntriesCompanion.insert(
          word: word,
          meaning: meaning,
          pronunciation: pronunciation != null
              ? Value(pronunciation)
              : const Value.absent(),
          language: Value(language),
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
  Future<int> deleteWords(List<int> ids) async {
    if (ids.isEmpty) return 0;
    // Xóa tags liên kết trước
    await (_db.delete(_db.vocabularyTags)
      ..where((t) => t.wordId.isIn(ids)))
        .go();
    return (_db.delete(_db.vocabularyEntries)
      ..where((t) => t.id.isIn(ids)))
        .go();
  }

  @override
  Future<bool> updateWord({
    required int id,
    required String word,
    required String meaning,
    String? pronunciation,
    String? language,
  }) =>
      _db.update(_db.vocabularyEntries).replace(
        VocabularyEntriesCompanion(
          id: Value(id),
          word: Value(word),
          meaning: Value(meaning),
          pronunciation: pronunciation != null
              ? Value(pronunciation)
              : const Value.absent(),
          language: Value(language),
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

  @override
  Future<void> updateWordSM2Progress({
    required int wordId,
    required double easeFactor,
    required int repetitions,
    required int interval,
    required DateTime nextReview,
  }) async {
    await (_db.update(_db.vocabularyEntries)
          ..where((t) => t.id.equals(wordId)))
        .write(VocabularyEntriesCompanion(
      easeFactor: Value(easeFactor),
      repetitions: Value(repetitions),
      interval: Value(interval),
      nextReview: Value(nextReview),
      lastReviewed: Value(DateTime.now()),
    ));
  }

  Future<void> changeWordState(int wordId, int newLevel, String? userId) async {
    final newStatus = _resolveStatus(newLevel);

    final companion = UserWordProgressEntrieCompanion(
      userId: Value(userId ?? ''),
      wordId: Value(wordId),
      status: Value(newStatus),
      lastPracticed: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    await _db.into(_db.userWordProgressEntrie).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> countWordLearn(String userId) async {
    await (_db.update(_db.usersEntrie)
      ..where((t) => t.keyOpen.equals(userId)))
        .write(UsersEntrieCompanion.custom(
      totalLearned: _db.usersEntrie.totalLearned + const Constant(1),
    ));
  }

  @override
  Future<bool> isWordAlreadyMastered(int wordId, String userId) async {
    final row = await (_db.select(_db.userWordProgressEntrie)
      ..where((t) => t.wordId.equals(wordId) & t.userId.equals(userId)))
        .getSingleOrNull();

    return row?.status == WordStatus.mastered;
  }

  int _resolveStatus(int level) {
    if (level >= 5) return WordStatus.mastered;
    if (level >= 1) return WordStatus.learning;
    return WordStatus.notStarted;
  }

  @override
  Future<List<String>> getLanguageTags() async {
    final query = _db.selectOnly(_db.vocabularyEntries, distinct: true)
      ..addColumns([
        _db.vocabularyEntries.language,
      ]);

    final rows = await query.get();

    return rows
        .map((row) => row.read(_db.vocabularyEntries.language))
        .whereType<String>()
        .toList();
  }

  @override
  Future<List<VocabularyEntry>> getWordsByLanguageTags(String? tags) async {
    final query = _db.select(_db.vocabularyEntries);

    if (tags != null && tags.isNotEmpty) {
      query.where((t) => t.language.equals(tags));
    }

    final rows = await query.get();

    return rows;
  }
}