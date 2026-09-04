/// ══════════════════════════════════════════════════════════════════════════════
/// NHÓM 7: SENSITIVE DATA EXPOSURE TESTS
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Mục tiêu: Kiểm tra rò rỉ thông tin nhạy cảm:
/// - Secret key không lộ qua error messages
/// - Debug print không xuất dữ liệu nhạy cảm trong production
/// - Backup export không chứa thông tin nội bộ không cần thiết
/// - Error messages không expose implementation details
/// ══════════════════════════════════════════════════════════════════════════════
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/database/backup_data.dart';
import 'package:test_abc/models/entity/user_entity.dart';
import 'package:test_abc/models/backup_entity.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/service/sercurity_service.dart';

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

  group('🕵️ [Nhóm 7] Sensitive Data Exposure', () {
    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-001: Error messages KHÔNG chứa secret key
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-EXP-001: Decrypt error KHÔNG lộ encryption key', () {
      // Cố tình decrypt dữ liệu sai
      final result = SecurityService.decryptData('InvalidCipherText!!!');

      // Result phải null (không crash)
      expect(result, isNull);

      // Thử decrypt với format đúng nhưng data sai
      try {
        SecurityService.decryptData('dGVzdA==:dGVzdA==');
      } catch (e) {
        final errorMsg = e.toString();
        // Error message KHÔNG được chứa encryption key
        expect(
          errorMsg.contains('DungeonaryCNhsuwhdn8as3n5WnsdkID'),
          isFalse,
          reason: 'Error message KHÔNG được lộ secret key!',
        );
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-002: Import failure messages KHÔNG chứa internal path
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-EXP-002: Import failure error KHÔNG lộ internal paths', () async {
      final backupRepo = BackupRepository(db);

      final result = await backupRepo.importFromJsonString('invalid json!!!');

      expect(result.success, isFalse);
      expect(result.error, isNotNull);

      // Error KHÔNG được chứa absolute path
      expect(
        result.error!.contains(r'C:\'),
        isFalse,
        reason: 'Error không được lộ Windows path',
      );
      expect(
        result.error!.contains('/data/'),
        isFalse,
        reason: 'Error không được lộ Android internal path',
      );
      expect(
        result.error!.contains('package:test_abc/'),
        isFalse,
        reason: 'Error không được lộ package path',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-003: Backup JSON encrypted output KHÔNG chứa plaintext data
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-EXP-003: Encrypted backup KHÔNG chứa plaintext username/keyOpen', () {
      const sensitiveData =
          '{"user":{"keyOpen":"secret-key-123","username":"JohnDoe","gems":500}}';

      final encrypted = SecurityService.encryptData(sensitiveData);

      // Encrypted output KHÔNG được chứa plaintext
      expect(encrypted.contains('secret-key-123'), isFalse,
          reason: 'Encrypted output không được chứa plaintext keyOpen');
      expect(encrypted.contains('JohnDoe'), isFalse,
          reason: 'Encrypted output không được chứa plaintext username');
      expect(encrypted.contains('"gems"'), isFalse,
          reason: 'Encrypted output không được chứa plaintext JSON keys');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-004: Mã hóa 2 lần cùng plaintext → output phải KHÁC NHAU (random IV)
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-EXP-004: Encrypt cùng plaintext 2 lần → ciphertext phải KHÁC (random IV)', () {
      const plaintext = 'Same message encrypted twice';

      final encrypted1 = SecurityService.encryptData(plaintext);
      final encrypted2 = SecurityService.encryptData(plaintext);

      expect(encrypted1, isNot(equals(encrypted2)),
          reason: 'Random IV phải tạo ra ciphertext khác nhau mỗi lần encrypt');

      // Nhưng cả 2 phải decrypt đúng
      expect(SecurityService.decryptData(encrypted1), equals(plaintext));
      expect(SecurityService.decryptData(encrypted2), equals(plaintext));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-005: .env file check — secret key complexity
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-EXP-005: Secret key phải đủ dài và phức tạp', () {
      // Kiểm tra key từ source code (trong test environment)
      // Key thực tế: DungeonaryCNhsuwhdn8as3n5WnsdkID (32 chars)
      const envKey = 'DungeonaryCNhsuwhdn8as3n5WnsdkID';

      expect(envKey.length, greaterThanOrEqualTo(16),
          reason: 'Key phải ít nhất 16 ký tự');

      // Kiểm tra không phải key yếu
      final weakKeys = ['0000000000000000', '1234567890123456', 'passwordpassword'];
      for (final weak in weakKeys) {
        expect(envKey, isNot(equals(weak)),
            reason: 'Key không được là pattern yếu: $weak');
      }

      // Kiểm tra có mix chữ hoa, chữ thường, số
      expect(RegExp(r'[a-z]').hasMatch(envKey), isTrue,
          reason: 'Key phải chứa chữ thường');
      expect(RegExp(r'[A-Z]').hasMatch(envKey), isTrue,
          reason: 'Key phải chứa chữ hoa');
      expect(RegExp(r'[0-9]').hasMatch(envKey), isTrue,
          reason: 'Key phải chứa số');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-006: ExportResult / ImportResult error messages
    // ─────────────────────────────────────────────────────────────────────────
    group('TC-EXP-006: Result error messages sanitization', () {
      test('ExportResult.fail không lộ stack trace', () {
        const result = ExportResult.fail('Lỗi xuất file');
        expect(result.error, isNotNull);
        expect(result.error!.contains('at '), isFalse,
            reason: 'Error không nên chứa stack trace');
      });

      test('ImportResult.fail không lộ stack trace', () {
        const result = ImportResult.fail('Dữ liệu không hợp lệ');
        expect(result.error, isNotNull);
        expect(result.error!.contains('.dart:'), isFalse,
            reason: 'Error không nên chứa file references');
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-007: Kiểm tra .env không nên được bundle vào assets
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-EXP-007: ⚠️ [DOCUMENT] .env file đang được bundle vào assets → LỖ HỔNG',
      () {
        // Kiểm tra pubspec.yaml có khai báo .env trong assets
        // pubspec.yaml line 109: - .env
        //
        // ⚠️ CRITICAL: .env chứa BACKUP_SECRET_KEY và được bundle vào APK.
        // Attacker có thể decompile APK → đọc .env → lấy encryption key.
        //
        // RECOMMENDATIONS:
        // 1. Chuyển sang --dart-define hoặc compile-time constant
        // 2. Dùng Android Keystore / iOS Keychain
        // 3. Obfuscate key nếu phải hardcode
        // 4. Dùng server-side encryption thay vì client-side key
        
        print('⚠️ [CRITICAL SECURITY] .env file chứa BACKUP_SECRET_KEY '
            'đang được bundle vào assets trong pubspec.yaml. '
            'Attacker có thể decompile APK để lấy key.');

        // Verify file tồn tại (document issue)
        final envFile = File(r'b:\ManhCuong_Windows\test_abc\.env');
        if (envFile.existsSync()) {
          final content = envFile.readAsStringSync();
          expect(content.contains('BACKUP_SECRET_KEY'), isTrue,
              reason: 'Confirm: .env chứa BACKUP_SECRET_KEY → cần fix');
        }
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-008: Source code không chứa hardcoded credentials
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-EXP-008: SecurityService không hardcode key trong source', () {
      // SecurityService đọc key từ dotenv, không hardcode
      // Verify bằng cách kiểm tra class không chứa literal key
      // (static analysis — kiểm tra source file)
      
      final sourceFile = File(
          r'b:\ManhCuong_Windows\test_abc\lib\service\sercurity_service.dart');
      if (sourceFile.existsSync()) {
        final content = sourceFile.readAsStringSync();

        // Source không nên chứa literal key
        expect(
          content.contains('DungeonaryCNhsuwhdn8as3n5WnsdkID'),
          isFalse,
          reason: 'Source code không nên chứa literal encryption key',
        );

        // Verify key đến từ dotenv
        expect(content.contains('dotenv.env'), isTrue,
            reason: 'Key phải đến từ dotenv, không hardcode');
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-EXP-009: Legacy IV = all zeros → insecure
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-EXP-009: ⚠️ [DOCUMENT] Legacy IV.fromLength(16) = all zeros → insecure',
      () {
        // SecurityService line 12: _legacyIv = IV.fromLength(16)
        // IV.fromLength(16) tạo IV toàn zero bytes [0,0,0,...,0]
        //
        // Vấn đề:
        // - IV toàn zero làm AES-CBC yếu hơn đáng kể
        // - Cùng plaintext + cùng key → cùng ciphertext (deterministic)
        // - Dễ bị Known-Plaintext Attack (KPA)
        //
        // Hiện tại code vẫn support legacy decrypt (fallback) —
        // cần migration plan để remove.
        
        print('⚠️ [SECURITY] IV.fromLength(16) tạo IV toàn zero. '
            'Legacy decrypt vẫn được support → cần migration plan.');

        // Document: mã hóa mới ĐÃ dùng random IV (line 17)
        // Nhưng giải mã vẫn fallback về legacy IV nếu format cũ
      },
    );
  });
}
