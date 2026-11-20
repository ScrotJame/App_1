import 'package:drift/drift.dart';
import 'package:test_abc/models/entity/learning_history_entity.dart';

import '../commons/status_comon.dart';
import '../database/app_db.dart';

/// One official daily-review answer, as the history log has it.
class LoggedReviewAnswer {
  const LoggedReviewAnswer({required this.isCorrect, required this.levelBefore});

  final bool isCorrect;

  /// `wordLevelSnapshot` of the log: the level before the answer was graded.
  final int levelBefore;
}

abstract class ILearningHistoryRepository {
  /// Records one answer from any learning mode: bumps the word's
  /// correct/wrong counter and adds a history row for the day.
  ///
  /// The level is left alone: only a Test and the feed's buttons change it,
  /// through VocabularyRepository.
  /// An unknown [wordId] records nothing. An empty [userKey] only updates the
  /// counter, because a history row needs a user.
  Future<void> recordAnswer({
    required String userKey,
    required int wordId,
    required int wordLevelSnapshot,
    required String sessionType,
    required bool isCorrect,
    DateTime? now,
  });

  /// Lấy danh sách ngày đã học (để render calendar/heatmap)
  Future<List<DateTime>> getActiveDates({String? userKey});

  /// Lấy chi tiết các từ đã học trong 1 ngày cụ thể
  Future<List<LearningHistoryEntity>> getHistoryByDate({
    String? userKey,
    DateTime? date,
    int? page,
    int? pageSize,
  });

  /// Đếm tổng số từ đã học trong 1 ngày cụ thể (để tính totalPage)
  Future<int> getHistoryCountByDate({String? userKey, DateTime? date});

  /// Official daily-review answers of [userKey] on the calendar day of [day],
  /// keyed by word id. When a word has several rows that day, the first wins.
  Future<Map<int, LoggedReviewAnswer>> getDailyReviewAnswers({
    required String userKey,
    required DateTime day,
  });
}

class LearningHistoryRepository implements ILearningHistoryRepository {
  final AppDatabase _db;
  LearningHistoryRepository(this._db);

  @override
  Future<void> recordAnswer({
    required String userKey,
    required int wordId,
    required int wordLevelSnapshot,
    required String sessionType,
    required bool isCorrect,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final words = _db.vocabularyEntries;
    await _db.transaction(() async {
      // Incremented in SQL so answers recorded back to back are not lost.
      final updated = await (_db.update(words)
            ..where((t) => t.id.equals(wordId)))
          .write(
        VocabularyEntriesCompanion.custom(
          correctCount:
              isCorrect ? words.correctCount + const Constant(1) : null,
          wrongCount: isCorrect ? null : words.wrongCount + const Constant(1),
        ),
      );
      if (updated == 0 || userKey.isEmpty) return;

      await _db.into(_db.learningHistoryLogs).insert(
            LearningHistoryLogsCompanion.insert(
              userKey: userKey,
              wordId: wordId,
              wordLevelSnapshot: wordLevelSnapshot,
              sessionType: sessionType,
              isCorrect: Value(isCorrect),
              learnedDate: DateTime.utc(at.year, at.month, at.day),
            ),
          );
    });
  }

  @override
  Future<List<DateTime>> getActiveDates({String? userKey}) {
    return (_db.selectOnly(_db.learningHistoryLogs)
      ..addColumns([_db.learningHistoryLogs.learnedDate])
      ..where(_db.learningHistoryLogs.userKey.equals(userKey ?? ''))
      ..groupBy([_db.learningHistoryLogs.learnedDate]))
        .map((row) => row.read(_db.learningHistoryLogs.learnedDate)!)
        .get();
  }

  @override
  Future<List<LearningHistoryEntity>> getHistoryByDate({
    String? userKey,
    DateTime? date,
    int? page,
    int? pageSize,
  }) {
    final safeDate = date ?? DateTime.now();
    final safePage = page ?? 1;
    final safePageSize = pageSize ?? 10;
    final startOfDay = DateTime.utc(safeDate.year, safeDate.month, safeDate.day);
    return (_db.select(_db.learningHistoryLogs).join([
      innerJoin(
        _db.vocabularyEntries,
        _db.vocabularyEntries.id
            .equalsExp(_db.learningHistoryLogs.wordId),
      )
    ])
      ..where(_db.learningHistoryLogs.userKey.equals(userKey ?? '') &
      _db.learningHistoryLogs.learnedDate.equals(startOfDay))
      ..orderBy([
        OrderingTerm.desc(_db.learningHistoryLogs.createdAt)
      ])
      ..limit(safePageSize, offset: (safePage - 1) * safePageSize))
        .map((row) => LearningHistoryEntity(
      word: row.readTable(_db.vocabularyEntries).word,
      meaning: row.readTable(_db.vocabularyEntries).meaning,
      wordLevelSnapshot:
      row.readTable(_db.learningHistoryLogs).wordLevelSnapshot,
      sessionType:
      row.readTable(_db.learningHistoryLogs).sessionType,
      isCorrect:
      row.readTable(_db.learningHistoryLogs).isCorrect,
      learnedDate:
      row.readTable(_db.learningHistoryLogs).learnedDate,
    ))
        .get();
  }

  @override
  Future<int> getHistoryCountByDate({String? userKey, DateTime? date}) async {
    final safeDate = date ?? DateTime.now();
    final startOfDay = DateTime.utc(safeDate.year, safeDate.month, safeDate.day);
    final countExp = _db.learningHistoryLogs.id.count();
    final query = _db.selectOnly(_db.learningHistoryLogs)
      ..addColumns([countExp])
      ..where(_db.learningHistoryLogs.userKey.equals(userKey ?? '') &
          _db.learningHistoryLogs.learnedDate.equals(startOfDay));
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  @override
  Future<Map<int, LoggedReviewAnswer>> getDailyReviewAnswers({
    required String userKey,
    required DateTime day,
  }) async {
    // Same day key as recordAnswer: the local date stored as UTC midnight.
    final startOfDay = DateTime.utc(day.year, day.month, day.day);
    final rows = await (_db.select(_db.learningHistoryLogs)
          ..where((t) =>
              t.userKey.equals(userKey) &
              t.sessionType.equals(SessionType.dailyReview) &
              t.learnedDate.equals(startOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    final answers = <int, LoggedReviewAnswer>{};
    for (final row in rows) {
      answers.putIfAbsent(
        row.wordId,
        () => LoggedReviewAnswer(
          isCorrect: row.isCorrect,
          levelBefore: row.wordLevelSnapshot,
        ),
      );
    }
    return answers;
  }
}
