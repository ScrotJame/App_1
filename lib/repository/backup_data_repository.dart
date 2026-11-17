import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/entity/word_progress_entity.dart';
import '../commons/status_comon.dart';
import '../database/backup_data.dart';
import '../helper/streak_date_helper.dart';
import '../models/backup_entity.dart';
import '../models/entity/achievement_progress_entity.dart';
import '../models/entity/active_companion_entity.dart';
import '../models/entity/activity_entity.dart';
import '../models/entity/companion_definition_entity.dart';
import '../models/entity/companion_history_entity.dart';
import '../models/entity/item_entity.dart';
import '../models/entity/learning_history_log_entity.dart';
import '../models/entity/tag_entity.dart';
import '../models/entity/unit_entity.dart';
import '../models/entity/user_entity.dart';
import '../models/entity/vocabulary_entity.dart';
import 'backup_user_merge.dart';
import 'user_repository.dart';
import '../service/auth_service.dart';
import '../service/cloud_service.dart';
import '../service/sercurity_service.dart';

abstract class IBackupRepository {
  // -- Export --

  /// Xuất file JSON và mở share sheet (AirDrop, Drive, Zalo, …)
  Future<ExportResult> exportAndShare();

  /// Lưu file JSON thẳng vào Downloads (Android) / Documents (iOS)
  Future<ExportResult> exportToFile();

  /// Upload JSON lên Firestore bằng secret key
  Future<ExportResult> exportToServer({String? secretKey});

  // -- Import --

  /// Mở file picker → chọn file .json → import
  Future<ImportResult> importFromFilePicker();

  /// Import trực tiếp từ một File object
  Future<ImportResult> importFromFile(File file);

  /// Nhập secret key → tải JSON từ Firestore → import
  Future<ImportResult> importFromServer({required String secretKey});

  /// Import từ JSON string thuần (dùng nội bộ hoặc test)
  Future<ImportResult> importFromJsonString(String jsonStr);

  Future<String?> getBackupKey();

  /// Tự động kiểm tra Firestore xem tài khoản hiện tại (theo uid) đã từng
  /// backup chưa, và nếu có thì tải bản mới nhất về, merge theo từng bản
  /// ghi (record nào có updatedAt mới hơn sẽ được giữ lại). Gọi ngay sau
  /// khi đăng nhập thành công trên thiết bị mới.
  Future<ImportResult> autoSyncFromServer();
}

// ─── Implementation ────────────────────────────────────────────────────────────

class BackupRepository implements IBackupRepository {
  final AppDatabase _db;
  final CloudService _cloudService;
  final AuthService _authService;
  static const String _localKeyPref = 'local_key';

  /// Backup file format written by this version of the app.
  static const int currentBackupVersion = 2;

  /// Builds the backup content as plain JSON text.
  Future<String> buildBackupJson() => _buildJsonString();

  BackupRepository(
      this._db, {
        CloudService? cloudService,
        AuthService? authService,
      })  : _cloudService = cloudService ?? CloudService(),
        _authService = authService ?? AuthService();

  @override
  Future<ExportResult> exportAndShare() async {
    try {
      final file = await _writeTempFile();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Dungeonary Backup',
      );

      return const ExportResult.ok();
    } catch (e) {
      return ExportResult.fail('Xuất và chia sẻ thất bại: $e');
    }
  }

  /// Opens the system "save as" dialog so the file lands outside the app's
  /// private folders. FileSaver.saveFile writes to getExternalFilesDir on
  /// Android, which is deleted together with the app.
  @override
  Future<ExportResult> exportToFile() async {
    try {
      final jsonStr = await _buildJsonString();
      final savedPath = await FileSaver.instance.saveAs(
        name: _buildFileNameWithoutExt(),
        bytes: Uint8List.fromList(utf8.encode(jsonStr)),
        fileExtension: 'json',
        mimeType: MimeType.json,
      );

      if (savedPath == null) return const ExportResult.cancelled();
      return ExportResult.ok(filePath: savedPath);
    } catch (e) {
      return ExportResult.fail('Lưu file thất bại: $e');
    }
  }

  /// Upload JSON lên Firestore với secretKey làm document ID.
  @override
  Future<ExportResult> exportToServer({String? secretKey}) async {
    try {
      final key = secretKey ?? await _authService.getBackupKey();
      if (key == null) {
        return const ExportResult.fail('Không lấy được backup key.');
      }
      final jsonStr = await _buildJsonString();
      final encryptedStr = SecurityService.encryptData(jsonStr);
      final success = await _cloudService.uploadBackup(key, encryptedStr);

      if (success) return const ExportResult.ok();
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
      final fileContent = await file.readAsString(encoding: utf8);
      final cleanContent = fileContent.trim();

      if (cleanContent.isEmpty) {
        return const ImportResult.fail('File rỗng, không có dữ liệu!');
      }
      if (!cleanContent.startsWith('{')) {
        return const ImportResult.fail(
          'File không phải bản backup JSON của Dungeonary.',
        );
      }

      return _parseAndMerge(cleanContent);
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

      final encryptedStr = await _cloudService.downloadBackup(secretKey);
      if (encryptedStr == null) {
        return const ImportResult.fail('Không tìm thấy backup nào với key này.');
      }
      final jsonStr = SecurityService.decryptData(encryptedStr);
      if (jsonStr == null) {
        return const ImportResult.fail('Dữ liệu trên server bị lỗi hoặc mã hóa không khớp!');
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
      return await _parseAndMerge(jsonStr);
    } catch (e) {
      return ImportResult.fail('Lỗi khi xử lý dữ liệu: $e');
    }
  }

  @override
  Future<String?> getBackupKey() => _authService.getBackupKey();

  @override
  Future<ImportResult> autoSyncFromServer() async {
    final uid = await _authService.getBackupKey();
    if (uid == null) {
      return const ImportResult.fail('Chưa đăng nhập.');
    }
    return importFromServer(secretKey: uid);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _buildFileNameWithoutExt() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'vocafire_backup_$ts';
  }

  Future<String> _buildJsonString() async {
    final backup = await _buildBackupData();
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  Future<File> _writeFile(String dirPath) async {
    final jsonStr = await _buildJsonString();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('$dirPath/vocafire_backup_$ts.json');
    await file.writeAsString(jsonStr, encoding: utf8);
    return file;
  }

  Future<File> _writeTempFile() async {
    final dir = await getTemporaryDirectory();
    return _writeFile(dir.path);
  }

  Future<ImportResult> _parseAndMerge(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return const ImportResult.fail('Dữ liệu không hợp lệ: JSON phải là một đối tượng');
      }
      if (decoded['version'] == null &&
          decoded['user'] == null &&
          decoded['vocabularies'] == null &&
          decoded['units'] == null) {
        return const ImportResult.fail('Dữ liệu không hợp lệ: Không tìm thấy trường backup hợp lệ');
      }
      final version = decoded['version'];
      if (version is int && version > currentBackupVersion) {
        return const ImportResult.fail(
          'File backup được tạo từ phiên bản app mới hơn. Vui lòng cập nhật app.',
        );
      }
      final backup = BackupData.fromJson(decoded);
      return await _mergeBackup(backup);
    } catch (e) {
      return ImportResult.fail('Dữ liệu không hợp lệ: $e');
    }
  }

  Future<BackupData> _buildBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    final localKey = prefs.getString(_localKeyPref);
    final user = localKey == null
        ? await (_db.select(_db.usersEntrie)..limit(1)).getSingle()
        : await (_db.select(_db.usersEntrie)
      ..where((u) => u.keyOpen.equals(localKey))
      ..limit(1))
        .getSingle();

    final activities = await (_db.select(_db.userActivitiesEntrie)
      ..where((t) => t.userKey.equals(user.keyOpen)))
        .get();

    final wordProgress = await (_db.select(_db.userWordProgressEntrie)
          ..where((t) => t.userId.equals(user.keyOpen)))
        .get();
    final units = await _db.select(_db.unitsEntries).get();
    final vocabularies = await _db.select(_db.vocabularyEntries).get();
    final tags = await _db.select(_db.tags).get();
    final vocabularyTags = await _db.select(_db.vocabularyTags).get();
    final userItems = await (_db.select(_db.userItemsEntrie)
          ..where((t) => t.userId.equals(user.keyOpen)))
        .get();
    final items = await _db.select(_db.itemsEntrie).get();
    final learningHistory = await (_db.select(_db.learningHistoryLogs)
          ..where((t) => t.userKey.equals(user.keyOpen))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final achievementRows = await (_db.select(_db.userAchievementProgress).join([
      innerJoin(
        _db.achievementDefinitions,
        _db.achievementDefinitions.id
            .equalsExp(_db.userAchievementProgress.achievementId),
      ),
    ])
          ..where(_db.userAchievementProgress.userKey.equals(user.keyOpen)))
        .get();
    final companionDefinitions =
        await _db.select(_db.companionDefinitions).get();
    final activeCompanion = await (_db.select(_db.activeCompanions)
          ..where((t) => t.userKey.equals(user.keyOpen)))
        .getSingleOrNull();
    final companionHistories = await (_db.select(_db.companionHistories)
          ..where((t) => t.userKey.equals(user.keyOpen))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final streakDates = [
      ...?prefs.getStringList(StreakDateHelper.prefKey),
    ]..sort();

    return BackupData(
      version: currentBackupVersion,
      exportedAt: DateTime.now(),
      userKey: user.keyOpen,
      streakDates: streakDates,
      user: UserEntity(
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
          .map((a) => ActivityEntity(
        userKey: a.userKey,
        activityDate: a.activityDate,
        note: a.note,
        createdAt: a.createdAt, id: a.id,
      ))
          .toList(),
      wordProgress: wordProgress
          .map((w) => WordProgressEntity(
        userId: w.userId,
        wordId: w.wordId,
        status: w.status,
        lastPracticed: w.lastPracticed,
        nextReview: w.nextReview,
        updatedAt: w.updatedAt,
      ))
          .toList(),
      units: units
          .map((u) => UnitEntity(
        id: u.id,
        title: u.title,
        createdAt: u.createdAt,
        updatedAt: u.updatedAt,
      ))
          .toList(),
      vocabularies: vocabularies
          .map((v) => VocabularyEntity(
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
        easeFactor: v.easeFactor,
        repetitions: v.repetitions,
        interval: v.interval,
        unitId: v.unitId,
        createdAt: v.createdAt,
        updatedAt: v.updatedAt,
      ))
          .toList(),
      tags: tags
          .map((t) => TagEntity(
        id: t.id,
        tagName: t.tagName,
        targetLanguage: t.targetLanguage,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      ))
          .toList(),
      vocabularyTags: vocabularyTags
          .map((vt) => VocabularyTagEntity(wordId: vt.wordId, tagId: vt.tagId))
          .toList(),
      userItems: userItems
          .map((i) => UserItemEntity(
        userId: i.userId,
        itemId: i.itemId,
        quantity: i.quantity,
      ))
          .toList(),
      items: items                                          // ← thêm
          .map((i) => ItemEntity(
        id: i.id,
        name: i.name,
        icon: i.icon,
        price: i.price,
        stock: i.stock,
        description: i.description,
        isSynced: i.isSynced,
        lastUpdated: i.lastUpdated,
      ))
          .toList(),
      // The sections below write their times in UTC, so they mean the same
      // moment on a device in another time zone. `learnedDate` depends on it:
      // it is the UTC midnight of the day the answer was given.
      learningHistory: learningHistory
          .map((log) => LearningHistoryLogEntity(
                wordId: log.wordId,
                wordLevelSnapshot: log.wordLevelSnapshot,
                sessionType: log.sessionType,
                isCorrect: log.isCorrect,
                learnedDate: log.learnedDate.toUtc(),
                createdAt: log.createdAt.toUtc(),
              ))
          .toList(),
      achievementProgress: achievementRows.map((row) {
        final progress = row.readTable(_db.userAchievementProgress);
        return AchievementProgressEntity(
          code: row.readTable(_db.achievementDefinitions).code,
          currentValue: progress.currentValue,
          isUnlocked: progress.isUnlocked,
          unlockedAt: progress.unlockedAt?.toUtc(),
          updatedAt: progress.updatedAt.toUtc(),
        );
      }).toList(),
      companionDefinitions: companionDefinitions
          .map((d) => CompanionDefinitionEntity(
                id: d.id,
                type: d.type,
                name: d.name,
              ))
          .toList(),
      activeCompanion: activeCompanion == null
          ? null
          : ActiveCompanionEntity(
              userKey: activeCompanion.userKey,
              definitionId: activeCompanion.definitionId,
              level: activeCompanion.level,
              foodInventory: activeCompanion.foodInventory,
              pendingWords: activeCompanion.pendingWords,
              foodUsedInCurrentLevel: activeCompanion.foodUsedInCurrentLevel,
              totalFoodUsed: activeCompanion.totalFoodUsed,
              totalWordsLearned: activeCompanion.totalWordsLearned,
              currentXpBonus: activeCompanion.currentXpBonus,
              isMaxLevel: activeCompanion.isMaxLevel,
              adoptedAt: activeCompanion.adoptedAt.toUtc(),
              updatedAt: activeCompanion.updatedAt.toUtc(),
            ),
      companionHistories: companionHistories
          .map((h) => CompanionHistoryEntity(
                id: h.id,
                userKey: h.userKey,
                definitionId: h.definitionId,
                levelReached: h.levelReached,
                totalFoodUsed: h.totalFoodUsed,
                totalWordsLearned: h.totalWordsLearned,
                adoptedAt: h.adoptedAt.toUtc(),
                deletedAt: h.deletedAt.toUtc(),
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
    int learningHistoryAdded = 0;
    int achievementsMerged = 0;
    int companionsMerged = 0;

    final prefs = await SharedPreferences.getInstance();
    final currentLocalKey = prefs.getString(_localKeyPref);
    final targetUserKey = currentLocalKey ?? backup.user?.keyOpen;

    await _db.transaction(() async {
      // ── 1. User ────────────────────────────────────────────────
      if (backup.user != null) {
        final existingUser = await (_db.select(_db.usersEntrie)
          ..where((t) => t.keyOpen.equals(targetUserKey ?? '')))
            .getSingleOrNull();

        final rawUsername = backup.user?.username ?? '';
        final safeUsername = (rawUsername.isNotEmpty && rawUsername.length >= 3)
            ? rawUsername
            : (existingUser != null && existingUser.username.length >= 3
                ? existingUser.username
                : 'User');

        final safeGems = (backup.user?.gems ?? 0).clamp(0, 1000000000);

        if (existingUser == null) {
          await _db.into(_db.usersEntrie).insert(
            UsersEntrieCompanion.insert(
              keyOpen: targetUserKey ?? '',
              username: safeUsername,
              currentStreak: Value(backup.user?.currentStreak ?? 0),
              longestStreak: Value(backup.user?.longestStreak ?? 0),
              totalLearned: Value(backup.user?.totalLearned ?? 0),
              lastActiveDate: Value(backup.user?.lastActiveDate),
              gems: Value(safeGems),
              level: Value(backup.user?.level ?? 0),
              experience: Value(backup.user?.experience ?? 0),
              createdAt: Value(backup.user?.createdAt ?? DateTime.now()),
              updatedAt: Value(backup.user?.updatedAt ?? DateTime.now()),
            ).copyWith(
              id: Value(backup.user?.id),
            ),
          );
          usersUpdated++;
        } else {
          await (_db.update(_db.usersEntrie)
            ..where((t) => t.keyOpen.equals(targetUserKey ?? '')))
              .write(mergeUserStats(
            existing: existingUser,
            backup: backup.user!,
            safeUsername: safeUsername,
            safeGems: safeGems,
          ));
          usersUpdated++;
        }
      }

      // Rows that belong to the user can only be written when that user
      // exists. Without one they would break the foreign key and roll the
      // whole import back, so those sections are skipped instead.
      final ownerKey =
          targetUserKey != null && await _userExists(targetUserKey)
              ? targetUserKey
              : null;

      // ── 2. Units ───────────────────────────────────────────────
      final unitIdMap = <int, int>{};

      for (final unit in backup.units ?? []) {
        final existing = await (_db.select(_db.unitsEntries)
          ..where((t) => t.title.equals(unit.title))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
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
      // Level of every word of the file as it is on this device after the
      // merge, and the words whose level the file raised.
      final wordLevels = <int, int>{};
      final raisedWordIds = <int>{};

      for (final VocabularyEntity vocab in backup.vocabularies ?? const []) {
        if (vocab.word == null || vocab.meaning == null) continue;

        final newUnitId =
            vocab.unitId != null ? unitIdMap[vocab.unitId] : null;

        final existing = await (_db.select(_db.vocabularyEntries)
          ..where((t) =>
              t.word.equals(vocab.word!) &
              t.meaning.equals(vocab.meaning!) &
              (newUnitId == null
                  ? t.unitId.isNull()
                  : t.unitId.equals(newUnitId)))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
            .getSingleOrNull();

        if (existing == null) {
          final inserted =
          await _db.into(_db.vocabularyEntries).insertReturningOrNull(
            VocabularyEntriesCompanion.insert(
              word: vocab.word!,
              meaning: vocab.meaning!,
              example: Value(vocab.example),
              pronunciation: Value(vocab.pronunciation),
              language: Value(vocab.language),
              level: Value(vocab.level ?? 1),
              correctCount: Value(vocab.correctCount ?? 0),
              wrongCount: Value(vocab.wrongCount ?? 0),
              isFavorite: Value(vocab.isFavorite ?? false),
              lastReviewed: Value(vocab.lastReviewed),
              nextReview: Value(vocab.nextReview),
              easeFactor: Value.absentIfNull(vocab.easeFactor),
              repetitions: Value.absentIfNull(vocab.repetitions),
              interval: Value.absentIfNull(vocab.interval),
              unitId: Value(newUnitId),
              createdAt: Value(vocab.createdAt ?? DateTime.now()),
              updatedAt: Value(vocab.updatedAt ?? DateTime.now()),
            ),
          );
          if (inserted != null) {
            if (vocab.id != null) vocabIdMap[vocab.id!] = inserted.id;
            wordLevels[inserted.id] = inserted.level;
            vocabulariesAdded++;
          }
        } else {
          if (vocab.id != null) vocabIdMap[vocab.id!] = existing.id;

          // Only an edit of the word moves updatedAt, so it decides nothing
          // but the edited fields.
          final fileUpdatedAt = vocab.updatedAt;
          final fileEditedLater = fileUpdatedAt != null &&
              fileUpdatedAt.isAfter(existing.updatedAt);

          // Answers and level changes leave updatedAt alone. Progress is
          // merged on its own, and a restore never lowers it.
          final level = math.max(existing.level, vocab.level ?? 0);
          final correctCount =
              math.max(existing.correctCount, vocab.correctCount ?? 0);
          final wrongCount =
              math.max(existing.wrongCount, vocab.wrongCount ?? 0);
          wordLevels[existing.id] = level;
          if (level > existing.level) raisedWordIds.add(existing.id);

          if (fileEditedLater ||
              level != existing.level ||
              correctCount != existing.correctCount ||
              wrongCount != existing.wrongCount) {
            await (_db.update(_db.vocabularyEntries)
              ..where((t) => t.id.equals(existing.id)))
                .write(VocabularyEntriesCompanion(
              level: Value(level),
              correctCount: Value(correctCount),
              wrongCount: Value(wrongCount),
              isFavorite: fileEditedLater
                  ? Value(vocab.isFavorite ?? existing.isFavorite)
                  : const Value.absent(),
              updatedAt:
                  fileEditedLater ? Value(fileUpdatedAt) : const Value.absent(),
            ));
          }

          // The review time, and the legacy SM-2 columns with it, follows the
          // later review.
          final fileReviewedLater = vocab.lastReviewed != null &&
              (existing.lastReviewed == null ||
                  vocab.lastReviewed!.isAfter(existing.lastReviewed!));
          if (fileReviewedLater) {
            await (_db.update(_db.vocabularyEntries)
              ..where((t) => t.id.equals(existing.id)))
                .write(VocabularyEntriesCompanion(
              easeFactor: Value.absentIfNull(vocab.easeFactor),
              repetitions: Value.absentIfNull(vocab.repetitions),
              interval: Value.absentIfNull(vocab.interval),
              lastReviewed: Value(vocab.lastReviewed),
              nextReview: Value(vocab.nextReview),
            ));
          }
        }
      }

      // ── 4. Tags ────────────────────────────────────────────────
      final tagIdMap = <int, int>{};

      for (final tag in backup.tags ?? []) {
        final existing = await (_db.select(_db.tags)
          ..where((t) => t.tagName.equals(tag.tagName))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
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
      for (final vt in backup.vocabularyTags ?? []) {
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
      if (ownerKey != null) {
        final existingCreatedAts = await (_db.select(_db.userActivitiesEntrie)
          ..where((t) => t.userKey.equals(ownerKey)))
            .get()
            .then((list) => list.map((a) => a.createdAt).toSet());

        for (final activity in backup.activities ?? []) {
          if (!existingCreatedAts.contains(activity.createdAt)) {
            await _db.into(_db.userActivitiesEntrie).insert(
              UserActivitiesEntrieCompanion.insert(
                userKey: ownerKey,
                activityDate: activity.activityDate,
                note: Value(activity.note),
                createdAt: Value(activity.createdAt),
              ),
            );
            activitiesAdded++;
          }
        }
      }

      // ── 7. WordProgress ────────────────────────────────────────
      if (ownerKey != null) {
        final progressTable = _db.userWordProgressEntrie;
        final wordsWithFileRow = <int>{};

        for (final WordProgressEntity progress
            in backup.wordProgress ?? const []) {
          // A word id only means something inside its own file. A row whose
          // word is not in the file cannot be placed, and guessing would
          // attach it to an unrelated word of this device.
          final wordId = vocabIdMap[progress.wordId];
          if (wordId == null) continue;
          wordsWithFileRow.add(wordId);

          // The status is derived from the level, so it is never left below
          // what the merged level stands for.
          final statusOfLevel = WordStatus.fromLevel(wordLevels[wordId] ?? 0);
          final status = math.max(
            (progress.status ?? WordStatus.notStarted)
                .clamp(WordStatus.notStarted, WordStatus.mastered),
            statusOfLevel,
          );
          final fileUpdatedAt = progress.updatedAt;

          final existing = await (_db.select(progressTable)
            ..where((t) =>
                t.userId.equals(ownerKey) & t.wordId.equals(wordId)))
              .getSingleOrNull();

          if (existing == null) {
            await _db.into(progressTable).insert(
              UserWordProgressEntrieCompanion.insert(
                userId: ownerKey,
                wordId: wordId,
                status: Value(status),
                lastPracticed: Value(progress.lastPracticed),
                nextReview: Value(progress.nextReview),
                updatedAt: Value.absentIfNull(fileUpdatedAt),
              ),
              mode: InsertMode.insertOrIgnore,
            );
            wordProgressMerged++;
          } else if (fileUpdatedAt != null &&
              fileUpdatedAt.isAfter(existing.updatedAt)) {
            await (_db.update(progressTable)
              ..where((t) =>
                  t.userId.equals(ownerKey) & t.wordId.equals(wordId)))
                .write(UserWordProgressEntrieCompanion(
              status: Value(status),
              lastPracticed: Value(progress.lastPracticed),
              nextReview: Value(progress.nextReview),
              updatedAt: Value(fileUpdatedAt),
            ));
            wordProgressMerged++;
          } else if (existing.status < statusOfLevel) {
            await (_db.update(progressTable)
              ..where((t) =>
                  t.userId.equals(ownerKey) & t.wordId.equals(wordId)))
                .write(UserWordProgressEntrieCompanion(
              status: Value(statusOfLevel),
            ));
          }
        }

        // Words whose level the file raised but that have no status row in
        // the file: the row already on this device follows the new level.
        for (final wordId in raisedWordIds.difference(wordsWithFileRow)) {
          final statusOfLevel = WordStatus.fromLevel(wordLevels[wordId] ?? 0);
          await (_db.update(progressTable)
            ..where((t) =>
                t.userId.equals(ownerKey) &
                t.wordId.equals(wordId) &
                t.status.isSmallerThanValue(statusOfLevel)))
              .write(UserWordProgressEntrieCompanion(
            status: Value(statusOfLevel),
          ));
        }
      }

      // ── 8. Items ───────────────────────────────────────────────
      // Item id in the file -> id of the same item on this device.
      final itemIdMap = <String, String>{};

      for (final ItemEntity item in backup.items ?? const []) {
        final fileId = item.id;
        if (fileId == null) continue;

        final existing = await (_db.select(_db.itemsEntrie)
          ..where((t) => t.id.equals(fileId)))
            .getSingleOrNull();

        if (existing != null) {
          itemIdMap[fileId] = fileId;
          if ((item.lastUpdated ?? DateTime(0)).isAfter(existing.lastUpdated)) {
            await (_db.update(_db.itemsEntrie)
              ..where((t) => t.id.equals(fileId)))
                .write(ItemsEntrieCompanion(
              name: Value(item.name ?? ''),
              icon: Value(item.icon ?? ''),
              price: Value(item.price ?? 0),
              stock: Value(item.stock ?? 0),
              description: Value(item.description),
              isSynced: Value(item.isSynced ?? false),
              lastUpdated: Value(item.lastUpdated ?? DateTime.now()),
            ));
          }
          continue;
        }

        final name = item.name ?? '';
        final icon = item.icon ?? '';
        if (name.isEmpty || icon.isEmpty) continue;

        // Item ids are generated per install, so the same catalogue item has
        // another id on another device. It is recognised by its name instead
        // of being added a second time.
        final sameName = await (_db.select(_db.itemsEntrie)
          ..where((t) => t.name.equals(name))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
            .getSingleOrNull();
        if (sameName != null) {
          itemIdMap[fileId] = sameName.id;
          continue;
        }

        await _db.into(_db.itemsEntrie).insert(
          ItemsEntrieCompanion.insert(
            id: Value(fileId),
            name: name,
            icon: icon,
            price: item.price ?? 0,
            stock: Value(item.stock ?? 0),
            description: Value(item.description),
            isSynced: Value(item.isSynced ?? false),
            lastUpdated: Value(item.lastUpdated ?? DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        itemIdMap[fileId] = fileId;
      }

      if (ownerKey != null) {
        // ── 9. UserItems ─────────────────────────────────────────
        userItemsMerged = await _mergeUserItems(
          backup.userItems ?? const [],
          ownerKey,
          itemIdMap,
        );

        // ── 10. Learning history ─────────────────────────────────
        learningHistoryAdded = await _mergeLearningHistory(
          backup.learningHistory ?? const [],
          ownerKey,
          vocabIdMap,
        );

        // ── 11. Achievements ─────────────────────────────────────
        achievementsMerged = await _mergeAchievements(
          backup.achievementProgress ?? const [],
          ownerKey,
        );

        // ── 12. Companion ────────────────────────────────────────
        companionsMerged = await _mergeCompanion(backup, ownerKey);
      }
    });

    await _mergeStreakDates(prefs, backup.streakDates);

    return ImportResult.ok(ImportSummary(
      usersUpdated: usersUpdated,
      activitiesAdded: activitiesAdded,
      wordProgressMerged: wordProgressMerged,
      unitsAdded: unitsAdded,
      vocabulariesAdded: vocabulariesAdded,
      tagsAdded: tagsAdded,
      vocabularyTagsAdded: vocabularyTagsAdded,
      userItemsMerged: userItemsMerged,
      learningHistoryAdded: learningHistoryAdded,
      achievementsMerged: achievementsMerged,
      companionsMerged: companionsMerged,
    ));
  }

  Future<bool> _userExists(String userKey) async {
    final user = await (_db.select(_db.usersEntrie)
          ..where((t) => t.keyOpen.equals(userKey)))
        .getSingleOrNull();
    return user != null;
  }

  /// Gives the user the items of the file. A quantity only goes up, the same
  /// way gems do. Returns how many rows were added or raised.
  Future<int> _mergeUserItems(
    List<UserItemEntity> fileItems,
    String userKey,
    Map<String, String> itemIdMap,
  ) async {
    final table = _db.userItemsEntrie;
    var merged = 0;

    for (final owned in fileItems) {
      final fileItemId = owned.itemId;
      if (fileItemId == null) continue;

      var itemId = itemIdMap[fileItemId];
      if (itemId == null) {
        // Not in the file's catalogue. The row is still usable when this
        // device has an item with that very id (a restore on the same
        // install); ids are UUIDs, so this cannot hit another item.
        final sameId = await (_db.select(_db.itemsEntrie)
              ..where((t) => t.id.equals(fileItemId)))
            .getSingleOrNull();
        if (sameId == null) continue;
        itemId = fileItemId;
      }
      final localItemId = itemId;

      final quantity = math.max(owned.quantity ?? 0, 0);
      final existing = await (_db.select(table)
            ..where((t) =>
                t.userId.equals(userKey) & t.itemId.equals(localItemId)))
          .getSingleOrNull();

      if (existing == null) {
        if (quantity == 0) continue;
        await _db.into(table).insert(UserItemsEntrieCompanion.insert(
              userId: userKey,
              itemId: localItemId,
              quantity: Value(quantity),
            ));
        merged++;
      } else if (quantity > existing.quantity) {
        await (_db.update(table)
              ..where((t) =>
                  t.userId.equals(userKey) & t.itemId.equals(localItemId)))
            .write(UserItemsEntrieCompanion(quantity: Value(quantity)));
        merged++;
      }
    }
    return merged;
  }

  /// Adds the answers of the file that this device does not have yet and
  /// returns how many were added.
  ///
  /// A history row has no identity of its own, so rows are matched by content
  /// and counted: importing the same file twice adds nothing, while two
  /// identical answers in one file are both kept.
  Future<int> _mergeLearningHistory(
    List<LearningHistoryLogEntity> fileLogs,
    String userKey,
    Map<int, int> vocabIdMap,
  ) async {
    if (fileLogs.isEmpty) return 0;
    final table = _db.learningHistoryLogs;

    String keyOf(int wordId, String sessionType, bool isCorrect, int level,
            DateTime learnedDate, DateTime createdAt) =>
        '$wordId|$sessionType|$isCorrect|$level|'
        '${_seconds(learnedDate)}|${_seconds(createdAt)}';

    final onDevice = <String, int>{};
    final deviceLogs = await (_db.select(table)
          ..where((t) => t.userKey.equals(userKey)))
        .get();
    for (final log in deviceLogs) {
      final key = keyOf(log.wordId, log.sessionType, log.isCorrect,
          log.wordLevelSnapshot, log.learnedDate, log.createdAt);
      onDevice[key] = (onDevice[key] ?? 0) + 1;
    }

    final missing = <LearningHistoryLogsCompanion>[];
    for (final log in fileLogs) {
      // An answer for a word that is not in the file cannot be placed.
      final wordId = vocabIdMap[log.wordId];
      final learnedDate = log.learnedDate;
      if (wordId == null || learnedDate == null) continue;

      final sessionType = log.sessionType ?? '';
      final isCorrect = log.isCorrect ?? false;
      final level = log.wordLevelSnapshot ?? 0;
      final createdAt = log.createdAt ?? learnedDate;

      final key =
          keyOf(wordId, sessionType, isCorrect, level, learnedDate, createdAt);
      final alreadyThere = onDevice[key] ?? 0;
      if (alreadyThere > 0) {
        onDevice[key] = alreadyThere - 1;
        continue;
      }

      missing.add(LearningHistoryLogsCompanion.insert(
        userKey: userKey,
        wordId: wordId,
        wordLevelSnapshot: level,
        sessionType: sessionType,
        isCorrect: Value(isCorrect),
        learnedDate: learnedDate,
        createdAt: Value(createdAt),
      ));
    }

    if (missing.isNotEmpty) {
      await _db.batch((b) => b.insertAll(table, missing));
    }
    return missing.length;
  }

  /// Merges achievement progress so that nothing already reached is lost: the
  /// higher value wins, an unlock stays unlocked and keeps its earliest time.
  /// Returns how many rows were added or changed.
  Future<int> _mergeAchievements(
    List<AchievementProgressEntity> fileProgress,
    String userKey,
  ) async {
    if (fileProgress.isEmpty) return 0;
    final table = _db.userAchievementProgress;

    final definitions = await _db.select(_db.achievementDefinitions).get();
    final idByCode = {for (final d in definitions) d.code: d.id};
    var merged = 0;

    for (final progress in fileProgress) {
      // An achievement this version of the app does not know is skipped.
      final achievementId = idByCode[progress.code];
      if (achievementId == null) continue;

      final fileValue = math.max(progress.currentValue ?? 0, 0);
      final fileUnlocked = progress.isUnlocked ?? false;
      final fileUnlockedAt = fileUnlocked ? progress.unlockedAt : null;

      final existing = await (_db.select(table)
            ..where((t) =>
                t.userKey.equals(userKey) &
                t.achievementId.equals(achievementId)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(table).insert(UserAchievementProgressCompanion.insert(
              userKey: userKey,
              achievementId: achievementId,
              currentValue: Value(fileValue),
              isUnlocked: Value(fileUnlocked),
              unlockedAt: Value(fileUnlockedAt),
              updatedAt: Value.absentIfNull(progress.updatedAt),
            ));
        merged++;
        continue;
      }

      final value = math.max(existing.currentValue, fileValue);
      final unlocked = existing.isUnlocked || fileUnlocked;
      final unlockedAt = _earlier(existing.unlockedAt, fileUnlockedAt);
      if (value == existing.currentValue &&
          unlocked == existing.isUnlocked &&
          unlockedAt == existing.unlockedAt) {
        continue;
      }

      await (_db.update(table)
            ..where((t) =>
                t.userKey.equals(userKey) &
                t.achievementId.equals(achievementId)))
          .write(UserAchievementProgressCompanion(
        currentValue: Value(value),
        isUnlocked: Value(unlocked),
        unlockedAt: Value(unlockedAt),
        updatedAt: Value(_later(existing.updatedAt, progress.updatedAt)),
      ));
      merged++;
    }
    return merged;
  }

  /// Restores the companion and the list of earlier companions. Returns how
  /// many rows were added or replaced.
  ///
  /// A user has one companion. When both the device and the file have one,
  /// the one that is further along stays; the device keeps its own on a tie.
  Future<int> _mergeCompanion(BackupData backup, String userKey) async {
    // Definition id in the file -> the same definition on this device. Ids
    // of the file are never used directly.
    final localDefinitions = await _db.select(_db.companionDefinitions).get();
    final definitionOfFileId = <int, CompanionDefinition>{};
    for (final CompanionDefinitionEntity fileDefinition
        in backup.companionDefinitions ?? const []) {
      final fileId = fileDefinition.id;
      if (fileId == null) continue;
      for (final local in localDefinitions) {
        if (local.type == fileDefinition.type &&
            local.name == fileDefinition.name) {
          definitionOfFileId[fileId] = local;
          break;
        }
      }
    }
    if (definitionOfFileId.isEmpty) return 0;

    var merged = 0;

    // ── Earlier companions ───────────────────────────────────────
    final histories = _db.companionHistories;
    String historyKey(
            int definitionId, DateTime adoptedAt, DateTime deletedAt) =>
        '$definitionId|${_seconds(adoptedAt)}|${_seconds(deletedAt)}';

    final deviceHistories = await (_db.select(histories)
          ..where((t) => t.userKey.equals(userKey)))
        .get();
    final knownHistories = {
      for (final h in deviceHistories)
        historyKey(h.definitionId, h.adoptedAt, h.deletedAt),
    };

    for (final CompanionHistoryEntity history
        in backup.companionHistories ?? const []) {
      final definition = definitionOfFileId[history.definitionId];
      final adoptedAt = history.adoptedAt;
      final deletedAt = history.deletedAt;
      if (definition == null || adoptedAt == null || deletedAt == null) {
        continue;
      }
      if (!knownHistories
          .add(historyKey(definition.id, adoptedAt, deletedAt))) {
        continue;
      }

      await _db.into(histories).insert(CompanionHistoriesCompanion.insert(
            userKey: userKey,
            definitionId: definition.id,
            levelReached: math.max(history.levelReached ?? 1, 1),
            totalFoodUsed: math.max(history.totalFoodUsed ?? 0, 0),
            totalWordsLearned:
                math.max(history.totalWordsLearned ?? 0, 0).toDouble(),
            adoptedAt: adoptedAt,
            deletedAt: Value(deletedAt),
          ));
      merged++;
    }

    // ── Current companion ────────────────────────────────────────
    final fileActive = backup.activeCompanion;
    final definition = definitionOfFileId[fileActive?.definitionId];
    if (fileActive == null || definition == null) return merged;

    final maxLevel = math.max(definition.maxLevel, 1);
    final level = (fileActive.level ?? 1).clamp(1, maxLevel);
    final totalFoodUsed = math.max(fileActive.totalFoodUsed ?? 0, 0);
    final totalWordsLearned =
        math.max(fileActive.totalWordsLearned ?? 0, 0).toDouble();

    final local = await (_db.select(_db.activeCompanions)
          ..where((t) => t.userKey.equals(userKey)))
        .getSingleOrNull();

    if (local != null) {
      final fileIsFurther = level != local.level
          ? level > local.level
          : totalFoodUsed != local.totalFoodUsed
              ? totalFoodUsed > local.totalFoodUsed
              : totalWordsLearned > local.totalWordsLearned;
      if (!fileIsFurther) return merged;

      // Replacing another kind of companion is a switch: the one that
      // leaves goes to the history, as it does when the user switches.
      if (local.definitionId != definition.id) {
        await _db.into(histories).insert(CompanionHistoriesCompanion.insert(
              userKey: userKey,
              definitionId: local.definitionId,
              levelReached: local.level,
              totalFoodUsed: local.totalFoodUsed,
              totalWordsLearned: local.totalWordsLearned,
              adoptedAt: local.adoptedAt,
            ));
      }
    }

    await _db.into(_db.activeCompanions).insertOnConflictUpdate(
          ActiveCompanionsCompanion.insert(
            userKey: userKey,
            definitionId: definition.id,
            level: Value(level),
            foodInventory: Value((fileActive.foodInventory ?? 0)
                .clamp(0, math.max(definition.maxFoodInventory, 0))),
            pendingWords:
                Value(math.max(fileActive.pendingWords ?? 0, 0).toDouble()),
            foodUsedInCurrentLevel:
                Value(math.max(fileActive.foodUsedInCurrentLevel ?? 0, 0)),
            totalFoodUsed: Value(totalFoodUsed),
            totalWordsLearned: Value(totalWordsLearned),
            // Derived from the level, with this device's definition.
            currentXpBonus: Value(definition.maxXpBonus * (level / maxLevel)),
            isMaxLevel: Value(level >= maxLevel),
            adoptedAt: Value.absentIfNull(fileActive.adoptedAt),
            updatedAt: Value.absentIfNull(fileActive.updatedAt),
          ),
        );
    return merged + 1;
  }

  /// Times are stored with second precision, so they are compared by it.
  static int _seconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

  /// The earlier of two optional times. Keeps [a] when both are the same
  /// moment.
  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return b.isBefore(a) ? b : a;
  }

  static DateTime _later(DateTime a, DateTime? b) =>
      b != null && b.isAfter(a) ? b : a;

  /// Adds the streak days from the file to the ones already on this device and
  /// recomputes the streak columns from the combined set, so a restore can
  /// only extend a streak.
  ///
  /// Files written before streak days were backed up have none. For those the
  /// columns merged by [mergeUserStats] are left as they are.
  Future<void> _mergeStreakDates(
    SharedPreferences prefs,
    List<String>? fileDates,
  ) async {
    if (fileDates == null) return;

    final today = StreakDateHelper.dateOnly(DateTime.now());
    final validDates = fileDates.where((key) {
      final day = StreakDateHelper.tryParseKey(key);
      return day != null && !day.isAfter(today);
    }).toSet();
    if (validDates.isEmpty) return;

    final merged = {
      ...?prefs.getStringList(StreakDateHelper.prefKey),
      ...validDates,
    }.toList()
      ..sort();
    await prefs.setStringList(StreakDateHelper.prefKey, merged);

    await UserRepository(_db).syncStreak();
  }
}
