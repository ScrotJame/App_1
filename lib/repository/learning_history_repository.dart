import 'package:drift/drift.dart';
import 'package:test_abc/models/entity/learning_history_entity.dart';

import '../database/app_db.dart';

abstract class ILearningHistoryRepository {
  /// Ghi log sau mỗi lần user trả lời 1 từ (trong Test)
  Future<void> logWordLearned({
    String? userKey,
    int? wordId,
    int? wordLevelSnapshot,
    String? sessionType,
    bool? isCorrect,
    bool? isLeveledUp,
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
}

class LearningHistoryRepository implements ILearningHistoryRepository {
  final AppDatabase _db;
  LearningHistoryRepository(this._db);

  @override
  Future<void> logWordLearned({
    String? userKey,
    int? wordId,
    int? wordLevelSnapshot,
    String? sessionType,
    bool? isCorrect,
    bool? isLeveledUp,
  }) async {
    await _db.into(_db.learningHistoryLogs).insert(
      LearningHistoryLogsCompanion.insert(
        userKey: userKey ?? '',
        wordId: wordId ?? 0,
        wordLevelSnapshot: wordLevelSnapshot ?? 0,
        sessionType: sessionType ?? '',
        isCorrect: Value(isCorrect ?? false),
        learnedDate: DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      ),
    );
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
}