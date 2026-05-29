import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:test_abc/models/entity/learning_history_entity.dart';

import '../database/app_db.dart';

abstract class ILearningHistoryRepository {
  /// Ghi log sau mỗi lần user trả lời 1 từ
  Future<void> logWordLearned({
    required String userKey,
    required int wordId,
    required int wordLevelSnapshot,
    required String sessionType,
    required bool isCorrect,
  });

  /// Lấy danh sách ngày đã học (để render calendar/heatmap)
  Future<List<DateTime>> getActiveDates({required String userKey});

  /// Lấy chi tiết các từ đã học trong 1 ngày cụ thể
  Future<List<LearningHistoryEntity>> getHistoryByDate({
    required String userKey,
    required DateTime date,
    required int page,
    required int pageSize,
  });
}

class LearningHistoryRepository implements ILearningHistoryRepository {
  final AppDatabase _db;
  LearningHistoryRepository(this._db);

  @override
  Future<void> logWordLearned({
    required String userKey,
    required int wordId,
    required int wordLevelSnapshot,
    required String sessionType,
    required bool isCorrect,}) async {
    await _db.into(_db.learningHistoryLogs).insert(
      LearningHistoryLogsCompanion.insert(
        userKey: userKey,
        wordId: wordId,
        wordLevelSnapshot:
        wordLevelSnapshot,
        sessionType: sessionType,
        isCorrect: Value(isCorrect),
        learnedDate: DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day,),
      ),
    );
  }

  @override
  Future<List<DateTime>> getActiveDates({required String userKey}) {
    return (_db.selectOnly(_db.learningHistoryLogs)
      ..addColumns([_db.learningHistoryLogs.learnedDate])
      ..where(_db.learningHistoryLogs.userKey.equals(userKey))
      ..groupBy([_db.learningHistoryLogs.learnedDate]))
        .map((row) => row.read(_db.learningHistoryLogs.learnedDate)!)
        .get();
  }

  @override
  Future<List<LearningHistoryEntity>> getHistoryByDate({
    required String userKey,
    required DateTime date,
    required int page,
    required int pageSize,
  }) {
    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    return (_db.select(_db.learningHistoryLogs).join([
      innerJoin(
        _db.vocabularyEntries,
        _db.vocabularyEntries.id
            .equalsExp(_db.learningHistoryLogs.wordId),
      )
    ])
      ..where(_db.learningHistoryLogs.userKey.equals(userKey) &
      _db.learningHistoryLogs.learnedDate.equals(startOfDay))
      ..orderBy([
        OrderingTerm.desc(_db.learningHistoryLogs.createdAt)
      ])
      ..limit(pageSize, offset: (page - 1) * pageSize))
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
}