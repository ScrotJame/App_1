import 'dart:math' as math;

import 'package:drift/drift.dart';
import '../commons/status_comon.dart';
import '../database/app_db.dart';
import '../helper/set_time_helper.dart';
import '../models/tag_vocab.dart';

/// What a review did to a word's level.
class WordLevelChange {
  const WordLevelChange({required this.word, required this.previousLevel});

  /// The word as stored after the change.
  final VocabularyEntry word;
  final int previousLevel;

  bool get leveledUp => word.level > previousLevel;

  bool get leveledDown => word.level < previousLevel;
}

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
  // ── Word progress ────────────────────────────────────────────────────────
  // `level` on the word is the only progress measure. Every method below
  // changes it in one transaction together with what is derived from it: the
  // user's status row and the `totalLearned` counter. All of them return null
  // for an unknown word.

  /// A correct Test answer: raises the level by one, but only when the word
  /// is due (see [SetTimeHelper.isDue]). A word that is not due is left as is.
  Future<WordLevelChange?> levelUpIfDue(int wordId, String userId,
      {DateTime? now});

  /// Keeps the level and starts the wait before the next level-up over. No
  /// longer used by Test (a wrong answer there calls [levelDown]).
  Future<WordLevelChange?> restartReviewWait(int wordId, String userId,
      {DateTime? now});

  /// A wrong answer in the daily review or in Test: the level drops by one (never below
  /// 0) and the wait before the next level-up starts over, even at level 0.
  Future<WordLevelChange?> levelDown(int wordId, String userId,
      {DateTime? now});

  /// "Đã thuộc": lifts the word to the mastered level.
  Future<WordLevelChange?> markWordMastered(int wordId, String userId,
      {DateTime? now});

  /// "Ôn lại": takes a mastered word back to learning. Other words are
  /// already in review and keep their level.
  Future<WordLevelChange?> returnWordToReview(int wordId, String userId,
      {DateTime? now});

  Future<bool> isWordAlreadyMastered(int wordId, String userId);

  /// The earliest moment after [now] at which a reviewed word is worth a
  /// reminder, or null when there is none.
  Future<DateTime?> nextReviewReminderTime({DateTime? now});

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
  }) async {
    // Writes only the edited columns. `replace()` would also reset every
    // column that has a default (level, counters, SM-2 schedule, createdAt).
    final count = await (_db.update(_db.vocabularyEntries)
          ..where((t) => t.id.equals(id)))
        .write(
      VocabularyEntriesCompanion(
        word: Value(word),
        meaning: Value(meaning),
        pronunciation: Value(pronunciation),
        language: Value(language),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return count > 0;
  }

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
  Future<WordLevelChange?> levelUpIfDue(int wordId, String userId,
      {DateTime? now}) {
    final at = now ?? DateTime.now();
    return _changeLevel(
      wordId,
      userId,
      at,
      (word) => SetTimeHelper.isDue(word.level, word.lastReviewed, at)
          ? word.level + 1
          : word.level,
    );
  }

  @override
  Future<WordLevelChange?> restartReviewWait(int wordId, String userId,
      {DateTime? now}) {
    return _changeLevel(
      wordId,
      userId,
      now ?? DateTime.now(),
      (word) => word.level,
      restartWait: true,
    );
  }

  @override
  Future<WordLevelChange?> levelDown(int wordId, String userId,
      {DateTime? now}) {
    return _changeLevel(
      wordId,
      userId,
      now ?? DateTime.now(),
      (word) => math.max(word.level - 1, 0),
      restartWait: true,
    );
  }

  @override
  Future<WordLevelChange?> markWordMastered(int wordId, String userId,
      {DateTime? now}) {
    return _changeLevel(
      wordId,
      userId,
      now ?? DateTime.now(),
      (word) => math.max(word.level, WordStatus.masteredLevel),
    );
  }

  @override
  Future<WordLevelChange?> returnWordToReview(int wordId, String userId,
      {DateTime? now}) {
    return _changeLevel(
      wordId,
      userId,
      now ?? DateTime.now(),
      (word) => math.min(word.level, WordStatus.masteredLevel - 1),
    );
  }

  /// The single place where a word's level is written. `lastReviewed` moves
  /// to [at] whenever the level changes or [restartWait] is set, the user's
  /// status row follows the level, and `totalLearned` moves by one each time
  /// the word crosses the mastered level, in either direction.
  Future<WordLevelChange?> _changeLevel(
    int wordId,
    String userId,
    DateTime at,
    int Function(VocabularyEntry word) decideLevel, {
    bool restartWait = false,
  }) {
    final words = _db.vocabularyEntries;
    final users = _db.usersEntrie;

    return _db.transaction(() async {
      final before = await (_db.select(words)
            ..where((t) => t.id.equals(wordId)))
          .getSingleOrNull();
      if (before == null) return null;

      final level = decideLevel(before);

      if (level != before.level || restartWait) {
        await (_db.update(words)..where((t) => t.id.equals(wordId))).write(
          VocabularyEntriesCompanion(
            level: Value(level),
            lastReviewed: Value(at),
          ),
        );
      }

      await _db.into(_db.userWordProgressEntrie).insertOnConflictUpdate(
            UserWordProgressEntrieCompanion(
              userId: Value(userId),
              wordId: Value(wordId),
              status: Value(WordStatus.fromLevel(level)),
              lastPracticed: Value(at),
              updatedAt: Value(at),
            ),
          );

      final wasMastered = before.level >= WordStatus.masteredLevel;
      final isMastered = level >= WordStatus.masteredLevel;
      if (isMastered && !wasMastered) {
        await (_db.update(users)..where((t) => t.keyOpen.equals(userId)))
            .write(UsersEntrieCompanion.custom(
          totalLearned: users.totalLearned + const Constant(1),
        ));
      } else if (wasMastered && !isMastered) {
        await (_db.update(users)
              ..where((t) =>
                  t.keyOpen.equals(userId) &
                  t.totalLearned.isBiggerThanValue(0)))
            .write(UsersEntrieCompanion.custom(
          totalLearned: users.totalLearned - const Constant(1),
        ));
      }

      final after = await (_db.select(words)
            ..where((t) => t.id.equals(wordId)))
          .getSingle();
      return WordLevelChange(word: after, previousLevel: before.level);
    });
  }

  @override
  Future<bool> isWordAlreadyMastered(int wordId, String userId) async {
    final row = await (_db.select(_db.userWordProgressEntrie)
      ..where((t) => t.wordId.equals(wordId) & t.userId.equals(userId)))
        .getSingleOrNull();

    return row?.status == WordStatus.mastered;
  }

  @override
  Future<DateTime?> nextReviewReminderTime({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final reviewed = await (_db.select(_db.vocabularyEntries)
          ..where((t) => t.lastReviewed.isNotNull()))
        .get();

    DateTime? earliest;
    for (final word in reviewed) {
      final lastReviewed = word.lastReviewed;
      if (lastReviewed == null) continue;
      final time = SetTimeHelper.reminderTime(word.level, lastReviewed);
      if (!time.isAfter(at)) continue;
      if (earliest == null || time.isBefore(earliest)) earliest = time;
    }
    return earliest;
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