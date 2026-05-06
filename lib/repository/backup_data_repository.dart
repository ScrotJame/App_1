import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:test_abc/database/app_db.dart';
import '../database/backup_data.dart';
import '../models/backup_entity.dart';
import '../service/cloud_service.dart';

abstract class IBackupRepository {
  // -- Export --

  /// Xuất file JSON và mở share sheet (AirDrop, Drive, Zalo, …)
  Future<ExportResult> exportAndShare();

  /// Lưu file JSON thẳng vào Downloads (Android) / Documents (iOS)
  Future<ExportResult> exportToFile();

  /// Upload JSON lên Firestore bằng secret key
  Future<ExportResult> exportToServer({required String secretKey});

  // -- Import --

  /// Mở file picker → chọn file .json → import
  Future<ImportResult> importFromFilePicker();

  /// Import trực tiếp từ một File object
  Future<ImportResult> importFromFile(File file);

  /// Nhập secret key → tải JSON từ Firestore → import
  Future<ImportResult> importFromServer({required String secretKey});

  /// Import từ JSON string thuần (dùng nội bộ hoặc test)
  Future<ImportResult> importFromJsonString(String jsonStr);
}

// ─── Implementation ────────────────────────────────────────────────────────────

class BackupRepository implements IBackupRepository {
  final AppDatabase _db;
  final CloudService _cloudService;

  /// [cloudService] có thể inject từ ngoài vào (tiện cho unit test).
  /// Nếu không truyền, tự tạo instance mặc định.
  BackupRepository(this._db, {CloudService? cloudService})
      : _cloudService = cloudService ?? CloudService();

  @override
  Future<ExportResult> exportAndShare() async {
    try {
      final file = await _writeTempFile();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'VocaFire Backup',
      );
      return const ExportResult.ok();
    } catch (e) {
      return ExportResult.fail('Xuất thất bại: $e');
    }
  }

  @override
  Future<ExportResult> exportToFile() async {
    try {
      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final file = await _writeFile(dir.path);
      return ExportResult.ok(filePath: file.path);
    } catch (e) {
      return ExportResult.fail('Lưu file thất bại: $e');
    }
  }

  /// Upload JSON lên Firestore với secretKey làm document ID.
  @override
  Future<ExportResult> exportToServer({required String secretKey}) async {
    try {
      final jsonStr = await _buildJsonString();
      final success = await _cloudService.uploadBackup(secretKey, jsonStr);

      if (success) {
        return const ExportResult.ok();
      }
      return const ExportResult.fail('Không thể upload lên server.');
    } on SocketException {
      return const ExportResult.fail('Không có kết nối mạng');
    } catch (e) {
      return ExportResult.fail('Upload thất bại: $e');
    }
  }

  @override
  Future<ImportResult> importFromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return const ImportResult.fail('Không có file nào được chọn');
    }

    return importFromFile(File(result.files.single.path!));
  }

  @override
  Future<ImportResult> importFromFile(File file) async {
    try {
      final jsonStr = await file.readAsString(encoding: utf8);
      return _parseAndMerge(jsonStr);
    } on FormatException catch (e) {
      return ImportResult.fail('File không hợp lệ: $e');
    } catch (e) {
      return ImportResult.fail('Lỗi khi đọc file: $e');
    }
  }

  /// Tải JSON từ Firestore bằng secretKey rồi merge vào DB local.
  @override
  Future<ImportResult> importFromServer({required String secretKey}) async {
    try {
      final jsonStr = await _cloudService.downloadBackup(secretKey);

      if (jsonStr == null) {
        return const ImportResult.fail(
            'Không tìm thấy backup nào với key này.');
      }

      return _parseAndMerge(jsonStr);
    } on SocketException {
      return const ImportResult.fail('Không có kết nối mạng');
    } catch (e) {
      return ImportResult.fail('Tải backup thất bại: $e');
    }
  }

  @override
  Future<ImportResult> importFromJsonString(String jsonStr) async {
    try {
      return _parseAndMerge(jsonStr);
    } catch (e) {
      return ImportResult.fail('Lỗi khi xử lý dữ liệu: $e');
    }
  }

  String _buildFileName() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'vocafire_backup_$ts.json';
  }

  Future<String> _buildJsonString() async {
    final backup = await _buildBackupData();
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  Future<File> _writeFile(String dirPath) async {
    final jsonStr = await _buildJsonString();
    final file = File('$dirPath/${_buildFileName()}');
    await file.writeAsString(jsonStr, encoding: utf8);
    return file;
  }

  Future<File> _writeTempFile() async {
    final dir = await getTemporaryDirectory();
    return _writeFile(dir.path);
  }

  Future<ImportResult> _parseAndMerge(String jsonStr) async {
    try {
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      final backup = BackupData.fromJson(jsonMap);
      return _mergeBackup(backup);
    } on FormatException catch (e) {
      return ImportResult.fail('Dữ liệu không hợp lệ: $e');
    }
  }

  Future<BackupData> _buildBackupData() async {
    final user = await (_db.select(_db.usersEntrie)..limit(1)).getSingle();

    final activities = await (_db.select(_db.userActivitiesEntrie)
      ..where((t) => t.userKey.equals(user.keyOpen)))
        .get();

    final wordProgress = await _db.select(_db.userWordProgressEntrie).get();
    final units = await _db.select(_db.unitsEntries).get();
    final vocabularies = await _db.select(_db.vocabularyEntries).get();
    final tags = await _db.select(_db.tags).get();
    final vocabularyTags = await _db.select(_db.vocabularyTags).get();
    final userItems = await _db.select(_db.userItemsEntrie).get();

    return BackupData(
      version: 1,
      exportedAt: DateTime.now(),
      userKey: user.keyOpen,
      user: BackupUser(
        id: user.id,
        keyOpen: user.keyOpen,
        username: user.username,
        currentStreak: user.currentStreak,
        longestStreak: user.longestStreak,
        totalLearned: user.totalLearned,
        lastActiveDate: user.lastActiveDate,
        gems: user.gems,
        level: user.level,
        experience: user.experience,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      ),
      activities: activities
          .map((a) => BackupActivity(
        id: a.id,
        userKey: a.userKey,
        activityDate: a.activityDate,
        note: a.note,
        createdAt: a.createdAt,
      ))
          .toList(),
      wordProgress: wordProgress
          .map((w) => BackupWordProgress(
        userId: w.userId,
        wordId: w.wordId,
        status: w.status,
        lastPracticed: w.lastPracticed,
        nextReview: w.nextReview,
        updatedAt: w.updatedAt,
      ))
          .toList(),
      units: units
          .map((u) => BackupUnit(
        id: u.id,
        title: u.title,
        createdAt: u.createdAt,
        updatedAt: u.updatedAt,
      ))
          .toList(),
      vocabularies: vocabularies
          .map((v) => BackupVocabulary(
        id: v.id,
        word: v.word,
        meaning: v.meaning,
        example: v.example,
        pronunciation: v.pronunciation,
        language: v.language,
        level: v.level,
        correctCount: v.correctCount,
        wrongCount: v.wrongCount,
        isFavorite: v.isFavorite,
        lastReviewed: v.lastReviewed,
        nextReview: v.nextReview,
        unitId: v.unitId,
        createdAt: v.createdAt,
        updatedAt: v.updatedAt,
      ))
          .toList(),
      tags: tags
          .map((t) => BackupTag(
        id: t.id,
        tagName: t.tagName,
        targetLanguage: t.targetLanguage,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      ))
          .toList(),
      vocabularyTags: vocabularyTags
          .map((vt) => BackupVocabularyTag(wordId: vt.wordId, tagId: vt.tagId))
          .toList(),
      userItems: userItems
          .map((i) => BackupUserItem(
        userId: i.userId,
        itemId: i.itemId,
        quantity: i.quantity,
      ))
          .toList(),
    );
  }

  Future<ImportResult> _mergeBackup(BackupData backup) async {
    int usersUpdated = 0;
    int activitiesAdded = 0;
    int wordProgressMerged = 0;
    int unitsAdded = 0;
    int vocabulariesAdded = 0;
    int tagsAdded = 0;
    int vocabularyTagsAdded = 0;
    int userItemsMerged = 0;

    await _db.transaction(() async {
      // ── 1. User ────────────────────────────────────────────────
      final existingUser = await (_db.select(_db.usersEntrie)
        ..where((t) => t.keyOpen.equals(backup.user.keyOpen)))
          .getSingleOrNull();

      if (existingUser == null) {
        await _db.into(_db.usersEntrie).insert(
          UsersEntrieCompanion.insert(
            keyOpen: backup.user.keyOpen,
            username: backup.user.username,
            currentStreak: Value(backup.user.currentStreak),
            longestStreak: Value(backup.user.longestStreak),
            totalLearned: Value(backup.user.totalLearned),
            lastActiveDate: Value(backup.user.lastActiveDate),
            gems: Value(backup.user.gems),
            level: Value(backup.user.level),
            experience: Value(backup.user.experience),
            createdAt: Value(backup.user.createdAt),
            updatedAt: Value(backup.user.updatedAt),
          ),
        );
        usersUpdated++;
      } else if (backup.user.updatedAt.isAfter(existingUser.updatedAt)) {
        await (_db.update(_db.usersEntrie)
          ..where((t) => t.keyOpen.equals(backup.user.keyOpen)))
            .write(UsersEntrieCompanion(
          username: Value(backup.user.username),
          currentStreak: Value(backup.user.currentStreak),
          longestStreak: Value(backup.user.longestStreak),
          totalLearned: Value(backup.user.totalLearned),
          lastActiveDate: Value(backup.user.lastActiveDate),
          gems: Value(backup.user.gems),
          level: Value(backup.user.level),
          experience: Value(backup.user.experience),
          updatedAt: Value(backup.user.updatedAt),
        ));
        usersUpdated++;
      }

      // ── 2. Units ───────────────────────────────────────────────
      final unitIdMap = <int, int>{};

      for (final unit in backup.units) {
        final existing = await (_db.select(_db.unitsEntries)
          ..where((t) => t.title.equals(unit.title)))
            .getSingleOrNull();

        if (existing == null) {
          final inserted = await _db.into(_db.unitsEntries).insertReturningOrNull(
            UnitsEntriesCompanion.insert(
              title: unit.title,
              createdAt: Value(unit.createdAt),
              updatedAt: Value(unit.updatedAt),
            ),
          );
          if (inserted != null) {
            unitIdMap[unit.id] = inserted.id;
            unitsAdded++;
          }
        } else {
          unitIdMap[unit.id] = existing.id;
          if (unit.updatedAt.isAfter(existing.updatedAt)) {
            await (_db.update(_db.unitsEntries)
              ..where((t) => t.id.equals(existing.id)))
                .write(UnitsEntriesCompanion(
              title: Value(unit.title),
              updatedAt: Value(unit.updatedAt),
            ));
          }
        }
      }

      // ── 3. Vocabularies ────────────────────────────────────────
      final vocabIdMap = <int, int>{};

      for (final vocab in backup.vocabularies) {
        final existing = await (_db.select(_db.vocabularyEntries)
          ..where((t) =>
          t.word.equals(vocab.word) & t.meaning.equals(vocab.meaning)))
            .getSingleOrNull();

        if (existing == null) {
          final newUnitId =
          vocab.unitId != null ? unitIdMap[vocab.unitId] : null;
          final inserted =
          await _db.into(_db.vocabularyEntries).insertReturningOrNull(
            VocabularyEntriesCompanion.insert(
              word: vocab.word,
              meaning: vocab.meaning,
              example: Value(vocab.example),
              pronunciation: Value(vocab.pronunciation),
              language: Value(vocab.language),
              level: Value(vocab.level),
              correctCount: Value(vocab.correctCount),
              wrongCount: Value(vocab.wrongCount),
              isFavorite: Value(vocab.isFavorite),
              lastReviewed: Value(vocab.lastReviewed),
              nextReview: Value(vocab.nextReview),
              unitId: Value(newUnitId),
              createdAt: Value(vocab.createdAt),
              updatedAt: Value(vocab.updatedAt),
            ),
          );
          if (inserted != null) {
            vocabIdMap[vocab.id] = inserted.id;
            vocabulariesAdded++;
          }
        } else {
          vocabIdMap[vocab.id] = existing.id;
          if (vocab.updatedAt.isAfter(existing.updatedAt)) {
            await (_db.update(_db.vocabularyEntries)
              ..where((t) => t.id.equals(existing.id)))
                .write(VocabularyEntriesCompanion(
              level: Value(vocab.level),
              correctCount: Value(vocab.correctCount),
              wrongCount: Value(vocab.wrongCount),
              isFavorite: Value(vocab.isFavorite),
              lastReviewed: Value(vocab.lastReviewed),
              nextReview: Value(vocab.nextReview),
              updatedAt: Value(vocab.updatedAt),
            ));
          }
        }
      }

      // ── 4. Tags ────────────────────────────────────────────────
      final tagIdMap = <int, int>{};

      for (final tag in backup.tags) {
        final existing = await (_db.select(_db.tags)
          ..where((t) => t.tagName.equals(tag.tagName)))
            .getSingleOrNull();

        if (existing == null) {
          final inserted = await _db.into(_db.tags).insertReturningOrNull(
            TagsCompanion.insert(
              tagName: tag.tagName,
              targetLanguage: Value(tag.targetLanguage),
              createdAt: Value(tag.createdAt),
              updatedAt: Value(tag.updatedAt),
            ),
          );
          if (inserted != null) {
            tagIdMap[tag.id] = inserted.id;
            tagsAdded++;
          }
        } else {
          tagIdMap[tag.id] = existing.id;
          if (tag.updatedAt.isAfter(existing.updatedAt)) {
            await (_db.update(_db.tags)
              ..where((t) => t.id.equals(existing.id)))
                .write(TagsCompanion(
              targetLanguage: Value(tag.targetLanguage),
              updatedAt: Value(tag.updatedAt),
            ));
          }
        }
      }

      // ── 5. VocabularyTags ──────────────────────────────────────
      for (final vt in backup.vocabularyTags) {
        final newWordId = vocabIdMap[vt.wordId];
        final newTagId = tagIdMap[vt.tagId];
        if (newWordId == null || newTagId == null) continue;

        final exists = await (_db.select(_db.vocabularyTags)
          ..where((t) =>
          t.wordId.equals(newWordId) & t.tagId.equals(newTagId)))
            .getSingleOrNull();

        if (exists == null) {
          await _db.into(_db.vocabularyTags).insert(
            VocabularyTagsCompanion.insert(wordId: newWordId, tagId: newTagId),
            mode: InsertMode.insertOrIgnore,
          );
          vocabularyTagsAdded++;
        }
      }

      // ── 6. Activities ──────────────────────────────────────────
      final existingCreatedAts = await (_db.select(_db.userActivitiesEntrie)
        ..where((t) => t.userKey.equals(backup.userKey)))
          .get()
          .then((list) => list.map((a) => a.createdAt).toSet());

      for (final activity in backup.activities) {
        if (!existingCreatedAts.contains(activity.createdAt)) {
          await _db.into(_db.userActivitiesEntrie).insert(
            UserActivitiesEntrieCompanion.insert(
              userKey: activity.userKey,
              activityDate: activity.activityDate,
              note: Value(activity.note),
              createdAt: Value(activity.createdAt),
            ),
          );
          activitiesAdded++;
        }
      }

      // ── 7. WordProgress ────────────────────────────────────────
      for (final progress in backup.wordProgress) {
        final newWordId = vocabIdMap[progress.wordId] ?? progress.wordId;

        final existing = await (_db.select(_db.userWordProgressEntrie)
          ..where((t) =>
          t.userId.equals(progress.userId) &
          t.wordId.equals(newWordId)))
            .getSingleOrNull();

        if (existing == null) {
          await _db.into(_db.userWordProgressEntrie).insert(
            UserWordProgressEntrieCompanion.insert(
              userId: progress.userId,
              wordId: newWordId,
              status: Value(progress.status),
              lastPracticed: Value(progress.lastPracticed),
              nextReview: Value(progress.nextReview),
              updatedAt: Value(progress.updatedAt),
            ),
            mode: InsertMode.insertOrIgnore,
          );
          wordProgressMerged++;
        } else if (progress.updatedAt.isAfter(existing.updatedAt)) {
          await (_db.update(_db.userWordProgressEntrie)
            ..where((t) =>
            t.userId.equals(progress.userId) &
            t.wordId.equals(newWordId)))
              .write(UserWordProgressEntrieCompanion(
            status: Value(progress.status),
            lastPracticed: Value(progress.lastPracticed),
            nextReview: Value(progress.nextReview),
            updatedAt: Value(progress.updatedAt),
          ));
          wordProgressMerged++;
        }
      }

      // ── 8. UserItems ───────────────────────────────────────────
      for (final item in backup.userItems) {
        final existing = await (_db.select(_db.userItemsEntrie)
          ..where((t) =>
          t.userId.equals(item.userId) & t.itemId.equals(item.itemId)))
            .getSingleOrNull();

        if (existing == null) {
          await _db.into(_db.userItemsEntrie).insert(
            UserItemsEntrieCompanion.insert(
              userId: item.userId,
              itemId: item.itemId,
              quantity: Value(item.quantity),
            ),
            mode: InsertMode.insertOrIgnore,
          );
          userItemsMerged++;
        } else if (item.quantity > existing.quantity) {
          await (_db.update(_db.userItemsEntrie)
            ..where((t) =>
            t.userId.equals(item.userId) &
            t.itemId.equals(item.itemId)))
              .write(
              UserItemsEntrieCompanion(quantity: Value(item.quantity)));
          userItemsMerged++;
        }
      }
    });

    return ImportResult.ok(ImportSummary(
      usersUpdated: usersUpdated,
      activitiesAdded: activitiesAdded,
      wordProgressMerged: wordProgressMerged,
      unitsAdded: unitsAdded,
      vocabulariesAdded: vocabulariesAdded,
      tagsAdded: tagsAdded,
      vocabularyTagsAdded: vocabularyTagsAdded,
      userItemsMerged: userItemsMerged,
    ));
  }
}