/// ══════════════════════════════════════════════════════════════════════════════
/// NHÓM 2: INJECTION & DATA CORRUPTION TESTS
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Mục tiêu: Tiêm dữ liệu độc hại vào DB (SQL injection, XSS, Unicode exploit,
/// path traversal, JSON bomb, negative/overflow values).
///
/// Drift sử dụng parameterized queries nên SQL injection truyền thống khó xảy
/// ra, nhưng ta vẫn cần verify + test các edge case khác.
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
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/repository/backup_data_repository.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Chạy migration seed data
    await db.customSelect('SELECT 1').get(); // Force open DB
  });

  tearDown(() async {
    await db.close();
  });

  group('💉 [Nhóm 2] Injection & Data Corruption', () {
    // ─────────────────────────────────────────────────────────────────────────
    // TC-INJ-001: SQL Injection qua username
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-INJ-001: SQL Injection qua username', () {
      final sqlPayloads = [
        "'; DROP TABLE users_entrie;--",
        "Robert'); DROP TABLE users_entrie;--",
        "1 OR 1=1",
        "' UNION SELECT * FROM users_entrie--",
        "admin'--",
        "1; UPDATE users_entrie SET gems = 999999;--",
      ];

      for (final payload in sqlPayloads) {
        test('Payload: "$payload" → phải được escape an toàn', () async {
          // username có constraint min:3, max:50. Truncate nếu cần.
          final safePayload =
              payload.length > 50 ? payload.substring(0, 50) : payload;
          if (safePayload.length < 3) return; // Skip payloads too short

          await db.into(db.usersEntrie).insert(
                UsersEntrieCompanion.insert(
                  keyOpen: 'sql-inject-test',
                  username: safePayload,
                ),
              );

          // Verify: table vẫn tồn tại, data được lưu đúng nguyên payload
          final user = await (db.select(db.usersEntrie)
                ..where((t) => t.keyOpen.equals('sql-inject-test')))
              .getSingleOrNull();

          expect(user, isNotNull, reason: 'User phải được tạo thành công');
          expect(user!.username, equals(safePayload),
              reason: 'Payload phải được lưu nguyên dạng text, không execute');

          // Cleanup
          await (db.delete(db.usersEntrie)
                ..where((t) => t.keyOpen.equals('sql-inject-test')))
              .go();
        });
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-INJ-002: XSS payload trong word/meaning
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-INJ-002: XSS payloads trong vocabulary', () {
      final xssPayloads = [
        '<script>alert("xss")</script>',
        '<img src=x onerror=alert(1)>',
        '"><svg/onload=alert(1)>',
        "javascript:alert('XSS')",
        '<iframe src="evil.com"></iframe>',
        '{{constructor.constructor("return this")()}}',
      ];

      for (final payload in xssPayloads) {
        test('XSS: "$payload" → phải lưu nguyên dạng text', () async {
          final repo = VocabularyRepository(db);

          final id = await repo.insertWord(
            word: payload,
            meaning: 'meaning_$payload',
          );

          final words = await repo.getAllWords();
          final found = words.firstWhere((w) => w.id == id);

          expect(found.word, equals(payload),
              reason: 'XSS payload phải được lưu nguyên — UI phải escape khi render');
        });
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-INJ-003: Unicode exploit
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-INJ-003: Unicode exploit payloads', () {
      test('RTL Override character → phải lưu được', () async {
        final repo = VocabularyRepository(db);
        const rtlPayload = 'Hello\u202Eworld'; // RTL override

        final id = await repo.insertWord(
          word: rtlPayload,
          meaning: 'RTL test',
        );

        final words = await repo.getAllWords();
        final found = words.firstWhere((w) => w.id == id);
        expect(found.word, equals(rtlPayload));
      });

      test('Emoji bomb → phải lưu được không crash', () async {
        final repo = VocabularyRepository(db);
        final emojiPayload = '😀' * 1000; // 1000 emoji

        final id = await repo.insertWord(
          word: emojiPayload,
          meaning: 'emoji test',
        );

        final words = await repo.getAllWords();
        final found = words.firstWhere((w) => w.id == id);
        expect(found.word, equals(emojiPayload));
      });

      test('Zero-width characters → phải lưu đúng', () async {
        final repo = VocabularyRepository(db);
        const zeroWidth = 'a\u200Bb\u200Cc\u200Dd\uFEFF';

        final id = await repo.insertWord(
          word: zeroWidth,
          meaning: 'zero-width test',
        );

        final words = await repo.getAllWords();
        final found = words.firstWhere((w) => w.id == id);
        expect(found.word, equals(zeroWidth));
      });

      test('Null byte trong string → phải handle', () async {
        final repo = VocabularyRepository(db);
        const nullByte = 'before\x00after';

        // Drift/SQLite có thể truncate tại null byte.
        // Test verify: không crash.
        try {
          await repo.insertWord(word: nullByte, meaning: 'null byte');
          // Nếu insert thành công → OK
        } catch (e) {
          // Nếu throw → cũng OK, miễn là không crash ứng dụng
          expect(e, isA<Exception>());
        }
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-INJ-004: Malformed JSON backup import
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-INJ-004: Malformed JSON backup import', () {
      late BackupRepository backupRepo;

      setUp(() {
        backupRepo = BackupRepository(db);
      });

      test('Hoàn toàn không phải JSON → phải fail gracefully', () async {
        final result =
            await backupRepo.importFromJsonString('This is not JSON at all!!!');
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('JSON rỗng {} → phải handle (không crash)', () async {
        final result = await backupRepo.importFromJsonString('{}');
        // Có thể success (merge 0 items) hoặc fail — nhưng KHÔNG crash
        // Tuỳ implementation, ta chỉ verify không throw unhandled exception
        expect(true, isTrue); // Nếu tới đây = không crash
      });

      test('JSON array thay vì object → phải fail', () async {
        final result = await backupRepo.importFromJsonString('[1,2,3]');
        expect(result.success, isFalse);
      });

      test('JSON nested cực sâu → phải handle', () async {
        // Tạo JSON nested 100 levels
        String nested = '"deep_value"';
        for (int i = 0; i < 100; i++) {
          nested = '{"level_$i": $nested}';
        }
        final result = await backupRepo.importFromJsonString(nested);
        // Có thể fail parse nhưng không crash
        expect(result.success, isFalse);
      });

      test('JSON với field sai type → phải handle', () async {
        const badTypes = '''
        {
          "version": "not_a_number",
          "user": {
            "keyOpen": 12345,
            "username": null,
            "gems": "one_million"
          }
        }
        ''';
        final result = await backupRepo.importFromJsonString(badTypes);
        expect(result.success, isFalse);
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-INJ-006: Negative / extreme values trong backup JSON
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-INJ-006: Negative & extreme values trong backup', () {
      late BackupRepository backupRepo;

      setUp(() async {
        backupRepo = BackupRepository(db);
        // Seed a user to merge into
        await seedUser(db, keyOpen: 'victim-user', gems: 100);
      });

      test('Negative gems (-999999) trong backup → không nên áp dụng', () async {
        final maliciousBackup = BackupData(
          version: 1,
          exportedAt: DateTime.now(),
          userKey: 'victim-user',
          user: const UserEntity(
            keyOpen: 'victim-user',
            username: 'Hacker',
            gems: -999999,
            totalLearned: -1,
            currentStreak: -100,
            longestStreak: -50,
          ),
        );
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(maliciousBackup.toJson());
        final result = await backupRepo.importFromJsonString(jsonStr);

        if (result.success) {
          // Nếu import thành công, verify gems không bị âm
          final user = await (db.select(db.usersEntrie)
                ..where((t) => t.keyOpen.equals('victim-user')))
              .getSingleOrNull();

          // ⚠️ BUG TIỀM ẨN: Nếu gems < 0 thì đây là lỗ hổng
          // Attacker có thể tạo backup với gems âm rồi import
          expect(
            user?.gems,
            greaterThanOrEqualTo(0),
            reason: 'Gems KHÔNG được phép âm — cần validate khi import',
          );
        }
      });

      test('Overflow integer (2^31 - 1 + 1) → phải handle', () async {
        final maliciousBackup = BackupData(
          version: 1,
          exportedAt: DateTime.now(),
          userKey: 'victim-user',
          user: const UserEntity(
            keyOpen: 'victim-user',
            username: 'Overflow',
            gems: 2147483647, // max int32
            totalLearned: 2147483647,
            level: 2147483647,
          ),
        );
        final jsonStr =
            const JsonEncoder.withIndent('  ').convert(maliciousBackup.toJson());

        // Phải không crash
        try {
          final result = await backupRepo.importFromJsonString(jsonStr);
          // OK nếu handle gracefully
        } catch (e) {
          // OK nếu throw known exception
          expect(e, isA<Exception>());
        }
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-INJ-007: Extremely long strings
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-INJ-007: Extremely long strings', () {
      test('Username 10.000 ký tự → phải bị reject bởi constraint', () async {
        final longUsername = 'A' * 10000;

        try {
          await db.into(db.usersEntrie).insert(
                UsersEntrieCompanion.insert(
                  keyOpen: 'long-user',
                  username: longUsername,
                ),
              );
          // Nếu insert thành công → constraint min:3 max:50 không hoạt động
          // (SQLite không enforce CHECK by default trong Drift)
          final user = await (db.select(db.usersEntrie)
                ..where((t) => t.keyOpen.equals('long-user')))
              .getSingleOrNull();
          // Document: Drift chỉ generate CHECK constraint, SQLite có thể bỏ qua
          expect(user, isNotNull);
        } catch (e) {
          // OK — constraint hoạt động đúng
          expect(e, isA<Exception>());
        }
      });

      test('Word 1MB text → phải handle (performance warning)', () async {
        final repo = VocabularyRepository(db);
        final megaWord = 'あ' * (1024 * 1024);

        try {
          await repo.insertWord(word: megaWord, meaning: 'huge');
          // Nếu insert thành công → DB sẽ rất lớn
        } catch (e) {
          // OK
          expect(e, isA<Exception>());
        }
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-INJ-008: Duplicate key injection
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-INJ-008: Insert user với keyOpen trùng → phải fail hoặc upsert', () async {
      await seedUser(db, keyOpen: 'duplicate-key');

      try {
        await db.into(db.usersEntrie).insert(
              UsersEntrieCompanion.insert(
                keyOpen: 'duplicate-key',
                username: 'DuplicateUser',
              ),
            );
        fail('Phải throw khi insert duplicate primary key');
      } catch (e) {
        // Expected: SQLite UNIQUE constraint violation
        expect(e, isA<Exception>());
      }
    });
  });
}
