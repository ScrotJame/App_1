import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/entity/word_progress_entity.dart';
import '../database/backup_data.dart';
import '../models/backup_entity.dart';
import '../models/entity/activity_entity.dart';
import '../models/entity/item_entity.dart';
import '../models/entity/tag_entity.dart';
import '../models/entity/unit_entity.dart';
import '../models/entity/user_entity.dart';
import '../models/entity/vocabulary_entity.dart';
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
}

// ─── Implementation ────────────────────────────────────────────────────────────

class BackupRepository implements IBackupRepository {
  final AppDatabase _db;
  final CloudService _cloudService;
  final AuthService _authService;
  static const String _localKeyPref = 'local_key';

  BackupRepository(
      this._db, {
        CloudService? cloudService,
        AuthService? authService,
      })  : _cloudService = cloudService ?? CloudService(),
        _authService = authService ?? AuthService();

  @override
  Future<ExportResult> exportAndShare() async {
    try {
      final jsonStr = await _buildJsonString();
      final encryptedStr = SecurityService.encryptData(jsonStr);
      final file = await _writeTempEncryptedFile(encryptedStr);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Dungeonary Backup',
      );

      return const ExportResult.ok();
    } catch (e) {
      return ExportResult.fail('Xuất và chia sẻ thất bại: $e');
    }
  }

  Future<File> _writeTempEncryptedFile(String encryptedData) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = '${_buildFileNameWithoutExt()}.json';
    final file = File('${tempDir.path}/$fileName');
    return await file.writeAsString(encryptedData);
  }

  /// Lưu file JSON vào thư mục Downloads bằng [file_saver].
  ///
  /// Android: ghi vào Downloads qua MediaStore (không cần xin quyền).
  /// iOS    : lưu vào Documents của app, có thể truy cập qua Files app.
  @override
  Future<ExportResult> exportToFile() async {
    try {
      final jsonStr = await _buildJsonString();
      final encryptedStr = SecurityService.encryptData(jsonStr);
      final bytes = Uint8List.fromList(utf8.encode(encryptedStr));
      final fileName = _buildFileNameWithoutExt();

      final savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'json',
        mimeType: MimeType.json,
      );

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
      print("📁 ĐANG ĐỌC FILE TỪ THIẾT BỊ...");
      print("   📍 Đường dẫn file: ${file.path}");

      final fileContent = await file.readAsString(encoding: utf8);
      print("   📄 Đọc file thành công. Tổng ký tự: ${fileContent.length}");

      if (fileContent.isEmpty) {
        return const ImportResult.fail('File rỗng, không có dữ liệu!');
      }

      final cleanContent = fileContent.trim();

      String? jsonStr;

      // Kiểm tra ký tự đầu tiên
      final firstChar = cleanContent.isNotEmpty ? cleanContent[0] : '';
      print("   🔍 Ký tự đầu tiên của file là: '$firstChar'");

      if (cleanContent.startsWith('{')) {
        print("   ⚠️ Phát hiện file JSON cũ (chưa mã hóa). Tiến hành nạp trực tiếp...");
        jsonStr = cleanContent;
      } else {
        print("   🔒 Phát hiện file mã hóa AES. Bắt đầu giải mã...");
        jsonStr = SecurityService.decryptData(cleanContent);
      }

      if (jsonStr == null) {
        return const ImportResult.fail('File đã bị can thiệp hoặc sai hệ thống giải mã!');
      }

      print("🔄 Bắt đầu Merge dữ liệu vào Database...");
      return _parseAndMerge(jsonStr);

    } on FormatException catch (e) {
      print("❌ LỖI FORMAT: $e");
      return ImportResult.fail('File không hợp lệ: $e');
    } catch (e) {
      print("❌ LỖI KHÔNG XÁC ĐỊNH KHI ĐỌC FILE: $e");
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
      return _parseAndMerge(jsonStr);
    } catch (e) {
      return ImportResult.fail('Lỗi khi xử lý dữ liệu: $e');
    }
  }

  @override
  Future<String?> getBackupKey() => _authService.getBackupKey();

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
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      final backup = BackupData.fromJson(jsonMap);
      return _mergeBackup(backup);
    } on FormatException catch (e) {
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

    final wordProgress = await _db.select(_db.userWordProgressEntrie).get();
    final units = await _db.select(_db.unitsEntries).get();
    final vocabularies = await _db.select(_db.vocabularyEntries).get();
    final tags = await _db.select(_db.tags).get();
    final vocabularyTags = await _db.select(_db.vocabularyTags).get();
    final userItems = await _db.select(_db.userItemsEntrie).get();
    final items = await _db.select(_db.itemsEntrie).get();

    return BackupData(
      version: 1,
      exportedAt: DateTime.now(),
      userKey: user.keyOpen,
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

    final prefs = await SharedPreferences.getInstance();
    final currentLocalKey = prefs.getString(_localKeyPref);
    final targetUserKey = currentLocalKey ?? backup.user?.keyOpen;

    await _db.transaction(() async {
      // ── 1. User ────────────────────────────────────────────────
      final existingUser = await (_db.select(_db.usersEntrie)
        ..where((t) => t.keyOpen.equals(targetUserKey ?? '')))
          .getSingleOrNull();

      if (existingUser == null) {
        await _db.into(_db.usersEntrie).insert(
          UsersEntrieCompanion.insert(
            keyOpen: targetUserKey ?? '',
            username: backup.user?.username ?? '',
            currentStreak: Value(backup.user?.currentStreak ?? 0),
            longestStreak: Value(backup.user?.longestStreak ?? 0),
            totalLearned: Value(backup.user?.totalLearned ?? 0),
            lastActiveDate: Value(backup.user?.lastActiveDate),
            gems: Value(backup.user?.gems ?? 0),
            level: Value(backup.user?.level ?? 0),
            experience: Value(backup.user?.experience ?? 0),
            createdAt: Value(backup.user?.createdAt ?? DateTime.now() ),
            updatedAt: Value(backup.user?.updatedAt ?? DateTime.now()),
          ).copyWith(
            id: Value(backup.user?.id),
          ),
        );
        usersUpdated++;
      } else {
        await (_db.update(_db.usersEntrie)
          ..where((t) => t.keyOpen.equals(targetUserKey ?? '')))
            .write(UsersEntrieCompanion(
          id: Value(backup.user?.id),
          username: Value(backup.user?.username ?? ''),
          currentStreak: Value(backup.user?.currentStreak ?? 0),
          longestStreak: Value(backup.user?.longestStreak ?? 0),
          totalLearned: Value(backup.user?.totalLearned ?? 0),
          lastActiveDate: Value(backup.user?.lastActiveDate),
          gems: Value(backup.user?.gems ?? 0),
          level: Value(backup.user?.level ?? 1),
          experience: Value(backup.user?.experience ?? 0),
          createdAt: Value(backup.user?.createdAt ?? DateTime.now()),
          updatedAt: Value(backup.user?.updatedAt ?? DateTime.now()),
        ));
        usersUpdated++;
      }

      // ── 2. Units ───────────────────────────────────────────────
      final unitIdMap = <int, int>{};

      for (final unit in backup.units ?? []) {
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

      for (final vocab in backup.vocabularies ?? []) {
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

      for (final tag in backup.tags ?? []) {
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
      final existingCreatedAts = await (_db.select(_db.userActivitiesEntrie)
        ..where((t) => t.userKey.equals(targetUserKey ?? '')))
          .get()
          .then((list) => list.map((a) => a.createdAt).toSet());

      for (final activity in backup.activities ?? []) {
        if (!existingCreatedAts.contains(activity.createdAt)) {
          await _db.into(_db.userActivitiesEntrie).insert(
            UserActivitiesEntrieCompanion.insert(
              userKey: targetUserKey ?? '',
              activityDate: activity.activityDate,
              note: Value(activity.note),
              createdAt: Value(activity.createdAt),
            ),
          );
          activitiesAdded++;
        }
      }

      // ── 7. WordProgress ────────────────────────────────────────
      for (final progress in backup.wordProgress ?? []) {
        final newWordId = vocabIdMap[progress.wordId] ?? progress.wordId;

        final existing = await (_db.select(_db.userWordProgressEntrie)
          ..where((t) =>
          t.userId.equals(targetUserKey ?? '') &
          t.wordId.equals(newWordId)))
            .getSingleOrNull();

        if (existing == null) {
          await _db.into(_db.userWordProgressEntrie).insert(
            UserWordProgressEntrieCompanion.insert(
              userId: targetUserKey ?? '',
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
            t.userId.equals(targetUserKey ?? '') &
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
      for (final item in backup.items ?? []) {
        final resolvedId = item.id;
        if (resolvedId == null) continue;

        final existing = await (_db.select(_db.itemsEntrie)
          ..where((t) => t.id.equals(resolvedId)))
            .getSingleOrNull();

        if (existing == null) {
          await _db.into(_db.itemsEntrie).insert(
            ItemsEntrieCompanion.insert(
              id: Value(resolvedId),
              name: item.name ?? '',
              icon: item.icon ?? '',
              price: item.price ?? 0,
              stock: Value(item.stock ?? 0),
              description: Value(item.description),
              isSynced: Value(item.isSynced ?? false),
              lastUpdated: Value(item.lastUpdated ?? DateTime.now()),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        } else if ((item.lastUpdated ?? DateTime(0)).isAfter(existing.lastUpdated)) {
          await (_db.update(_db.itemsEntrie)
            ..where((t) => t.id.equals(resolvedId)))
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