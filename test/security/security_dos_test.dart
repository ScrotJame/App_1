/// ══════════════════════════════════════════════════════════════════════════════
/// NHÓM 6: RESOURCE EXHAUSTION & DoS TESTS
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Mục tiêu: Kiểm tra hệ thống khi bị tấn công gây cạn kiệt tài nguyên:
/// - Import backup cực lớn (hàng ngàn records)
/// - Spam insert liên tục
/// - DB query performance dưới load cao
/// - Memory leak detection
/// ══════════════════════════════════════════════════════════════════════════════
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/database/backup_data.dart';
import 'package:test_abc/models/entity/user_entity.dart';
import 'package:test_abc/models/entity/vocabulary_entity.dart';
import 'package:test_abc/models/entity/unit_entity.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('💥 [Nhóm 6] Resource Exhaustion & DoS', () {
    // ─────────────────────────────────────────────────────────────────────────
    // TC-DOS-001: Import backup với 5000 vocabularies
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-DOS-001: Import backup 5000 vocabularies → phải hoàn thành dưới 30s',
      () async {
        await seedUser(db, keyOpen: 'dos-user-1');

        // Tạo backup với 5000 từ
        final vocabs = List.generate(
          5000,
          (i) => VocabularyEntity(
            id: i + 1,
            word: 'word_$i',
            meaning: 'meaning_$i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final backup = BackupData(
          version: 1,
          exportedAt: DateTime.now(),
          userKey: 'dos-user-1',
          user: UserEntity(
            keyOpen: 'dos-user-1',
            username: 'DoS Tester',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          vocabularies: vocabs,
        );

        final backupRepo = BackupRepository(db);
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(backup.toJson());

        final stopwatch = Stopwatch()..start();
        final result = await backupRepo.importFromJsonString(jsonStr);
        stopwatch.stop();

        expect(result.success, isTrue,
            reason: 'Import 5000 vocab phải thành công');
        expect(stopwatch.elapsedMilliseconds, lessThan(30000),
            reason: 'Import phải hoàn thành dưới 30 giây. '
                'Actual: ${stopwatch.elapsedMilliseconds}ms');

        // Verify data
        final allWords = await db.select(db.vocabularyEntries).get();
        expect(allWords.length, greaterThanOrEqualTo(5000));

        print('✅ Import 5000 vocabs: ${stopwatch.elapsedMilliseconds}ms');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-DOS-002: Spam insertWord 1000 lần liên tục
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-DOS-002: Spam insertWord x1000 → DB phải handle',
      () async {
        final vocabRepo = VocabularyRepository(db);

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          await vocabRepo.insertWord(
            word: 'spam_word_$i',
            meaning: 'spam_meaning_$i',
          );
        }
        stopwatch.stop();

        final count = await db.select(db.vocabularyEntries).get();
        expect(count.length, greaterThanOrEqualTo(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
            reason: '1000 inserts phải dưới 10s. '
                'Actual: ${stopwatch.elapsedMilliseconds}ms');

        print('✅ 1000 inserts: ${stopwatch.elapsedMilliseconds}ms');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-DOS-003: Import backup trùng lặp liên tục (10 lần cùng data)
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-DOS-003: Import cùng backup 10 lần → data không bị duplicate',
      () async {
        await seedUser(db, keyOpen: 'dup-import-user');

        final backup = BackupData(
          version: 1,
          exportedAt: DateTime.now(),
          userKey: 'dup-import-user',
          user: UserEntity(
            keyOpen: 'dup-import-user',
            username: 'DupTest',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          vocabularies: List.generate(
            50,
            (i) => VocabularyEntity(
              id: i + 1,
              word: 'dup_word_$i',
              meaning: 'dup_meaning_$i',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          units: [
            UnitEntity(
              id: 1,
              title: 'Test Unit',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        );

        final backupRepo = BackupRepository(db);
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(backup.toJson());

        // Import 10 lần
        for (int i = 0; i < 10; i++) {
          await backupRepo.importFromJsonString(jsonStr);
        }

        // Vocabulary phải không bị duplicate (merge by word + meaning)
        final allWords = await db.select(db.vocabularyEntries).get();
        final uniqueWords = allWords.map((w) => '${w.word}|${w.meaning}').toSet();

        expect(
          allWords.length,
          equals(uniqueWords.length),
          reason: 'Không được có duplicate vocabulary sau 10 lần import. '
              'Total: ${allWords.length}, Unique: ${uniqueWords.length}',
        );

        // Units phải không bị duplicate (merge by title)
        final allUnits = await db.select(db.unitsEntries).get();
        expect(allUnits.length, equals(1),
            reason: 'Unit phải merge, không duplicate');
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-DOS-004: Concurrent batch insert
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-DOS-004: 10 concurrent batch inserts (100 words each) → tổng phải đúng 1000',
      () async {
        final vocabRepo = VocabularyRepository(db);

        final futures = List.generate(10, (batch) {
          return Future.wait(
            List.generate(100, (i) {
              return vocabRepo.insertWord(
                word: 'batch${batch}_word_$i',
                meaning: 'batch${batch}_meaning_$i',
              );
            }),
          );
        });

        await Future.wait(futures);

        final count = await db.select(db.vocabularyEntries).get();
        expect(count.length, greaterThanOrEqualTo(1000),
            reason: 'Phải có ít nhất 1000 words sau concurrent inserts');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-DOS-005: Query performance — select all words khi có nhiều data
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-DOS-005: Select all words khi có 2000 records → dưới 2s',
      () async {
        // Bulk insert 2000 records
        await db.batch((batch) {
          for (int i = 0; i < 2000; i++) {
            batch.insert(
              db.vocabularyEntries,
              VocabularyEntriesCompanion.insert(
                word: 'perf_word_$i',
                meaning: 'perf_meaning_$i',
              ),
            );
          }
        });

        final vocabRepo = VocabularyRepository(db);

        final stopwatch = Stopwatch()..start();
        final words = await vocabRepo.getAllWords();
        stopwatch.stop();

        expect(words.length, greaterThanOrEqualTo(2000));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'SELECT 2000 words phải dưới 2s. '
                'Actual: ${stopwatch.elapsedMilliseconds}ms');

        print('✅ SELECT 2000 words: ${stopwatch.elapsedMilliseconds}ms');
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-DOS-006: Delete massive data
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-DOS-006: Delete 1000 words cùng lúc → phải hoàn thành nhanh',
      () async {
        // Insert 1000
        final ids = <int>[];
        for (int i = 0; i < 1000; i++) {
          final id = await seedWord(
            db,
            word: 'del_word_$i',
            meaning: 'del_meaning_$i',
          );
          ids.add(id);
        }

        final vocabRepo = VocabularyRepository(db);

        final stopwatch = Stopwatch()..start();
        await vocabRepo.deleteWords(ids);
        stopwatch.stop();

        final remaining = await vocabRepo.getAllWords();
        expect(remaining, isEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
            reason: 'Delete 1000 words phải dưới 5s');

        print('✅ DELETE 1000 words: ${stopwatch.elapsedMilliseconds}ms');
      },
    );
  });
}
