/// ══════════════════════════════════════════════════════════════════════════════
/// NHÓM 1: ENCRYPTION & DATA TAMPERING TESTS
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Mục tiêu: Kiểm tra khả năng chống chịu của hệ thống mã hóa AES khi
/// attacker cố tình can thiệp vào ciphertext, IV, key, hoặc bypass mã hóa.
///
/// Các kịch bản tấn công:
///   TC-SEC-001: Giải mã với key sai
///   TC-SEC-002: Tamper ciphertext (đổi byte)
///   TC-SEC-003: Tamper IV (đổi byte)
///   TC-SEC-004: Replay attack — dùng IV cũ với ciphertext mới
///   TC-SEC-005: Empty / null input không được crash
///   TC-SEC-006: JSON plaintext bypass (BUG hiện tại)
///   TC-SEC-007: Input cực lớn → OOM check
///   TC-SEC-008: Cắt ngắn ciphertext
///   TC-SEC-009: Base64 không hợp lệ
///   TC-SEC-010: Format ':' lồng nhau / giả mạo
/// ══════════════════════════════════════════════════════════════════════════════
import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/service/sercurity_service.dart';

void main() {
  setUpAll(() async {
    // Load .env để SecurityService có thể đọc BACKUP_SECRET_KEY
    await dotenv.load(fileName: '.env');
  });

  group('🔐 [Nhóm 1] Encryption & Data Tampering', () {
    // ─── Chuẩn bị dữ liệu test ─────────────────────────────────────────────
    const sampleJson = '{"user":{"keyOpen":"abc-123","gems":500},"version":1}';

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-001: Mã hóa rồi giải mã đúng → roundtrip phải khớp
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-001: Encrypt → Decrypt roundtrip phải trả về dữ liệu gốc', () {
      final encrypted = SecurityService.encryptData(sampleJson);
      final decrypted = SecurityService.decryptData(encrypted);

      expect(decrypted, isNotNull);
      expect(decrypted, equals(sampleJson));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-002: Tamper ciphertext — đổi 1 byte trong phần cipher
    // Kỳ vọng: decrypt phải trả null hoặc throw (KHÔNG trả dữ liệu sai)
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-002: Tamper ciphertext → phải reject (null hoặc exception)', () {
      final encrypted = SecurityService.encryptData(sampleJson);
      final parts = encrypted.split(':');
      expect(parts.length, 2, reason: 'Cấu trúc mã hóa phải là IV:cipher');

      // Đổi 1 ký tự trong phần cipher
      final tamperedCipher = _flipBit(parts[1]);
      final tampered = '${parts[0]}:$tamperedCipher';

      final result = SecurityService.decryptData(tampered);

      // Phải null hoặc khác original (padding error thường → null)
      expect(
        result == null || result != sampleJson,
        isTrue,
        reason: 'Dữ liệu bị tamper KHÔNG được giải mã thành dữ liệu gốc',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-003: Tamper IV — đổi 1 byte trong phần IV
    // Kỳ vọng: decrypt phải trả null hoặc dữ liệu bị lỗi
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-003: Tamper IV → phải reject hoặc trả dữ liệu sai', () {
      final encrypted = SecurityService.encryptData(sampleJson);
      final parts = encrypted.split(':');

      // Đổi 1 ký tự trong phần IV
      final tamperedIv = _flipBit(parts[0]);
      final tampered = '$tamperedIv:${parts[1]}';

      final result = SecurityService.decryptData(tampered);

      // CBC mode: IV tamper → decrypt thành garbage (block 1 bị sai)
      // hoặc null nếu padding check fail
      expect(
        result == null || result != sampleJson,
        isTrue,
        reason: 'IV bị tamper → dữ liệu giải mã PHẢI khác gốc',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-004: Replay attack — lấy IV từ message A, cipher từ message B
    // Kỳ vọng: phải fail
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-004: Replay attack (IV message A + cipher message B) → phải fail', () {
      final encryptedA = SecurityService.encryptData('Message A secret');
      final encryptedB = SecurityService.encryptData('Message B secret');

      final ivA = encryptedA.split(':')[0];
      final cipherB = encryptedB.split(':')[1];

      final replayed = '$ivA:$cipherB';
      final result = SecurityService.decryptData(replayed);

      // Phải null hoặc khác cả hai message gốc
      expect(
        result == null ||
            (result != 'Message A secret' && result != 'Message B secret'),
        isTrue,
        reason: 'Replay attack phải bị ngăn chặn',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-005: Empty / whitespace input → KHÔNG crash
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-005: Empty string → phải trả null, KHÔNG crash', () {
      expect(SecurityService.decryptData(''), isNull);
    });

    test('TC-SEC-005b: Whitespace only → phải trả null, KHÔNG crash', () {
      expect(SecurityService.decryptData('   \n\t  '), isNull);
    });

    test('TC-SEC-005c: ⚠️ [BUG] Encrypt empty string → crashes with RangeError', () {
      // BUG: SecurityService.encryptData('') throws RangeError
      // vì encrypt package không xử lý empty input.
      // Recommendation: Thêm guard `if (rawJson.isEmpty) return '';`
      expect(
        () => SecurityService.encryptData(''),
        throwsA(isA<RangeError>()),
        reason: 'Encrypt empty string gây crash — cần fix',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-006: ⚠️ BUG — Plaintext JSON bypass mã hóa
    // File backup_data_repository.dart dòng 181: startsWith('{')
    // Attacker có thể craft file JSON không mã hóa → import thẳng
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'TC-SEC-006: [KNOWN BUG] Plaintext JSON KHÔNG nên được chấp nhận bởi import flow',
      () {
        // Kịch bản: Attacker tạo file backup giả không mã hóa
        const maliciousJson = '{"version":1,"user":{"keyOpen":"hacked","gems":999999}}';

        // Hiện tại backup_data_repository.dart cho phép nếu file startsWith('{')
        // Test này document BUG — nên fix bằng cách BỎ nhánh startsWith('{')
        // hoặc thêm HMAC signature verification.

        // Nếu decrypt được plaintext → BUG
        // SecurityService.decryptData KHÔNG phải chỗ check, nhưng ta verify
        // rằng decrypt plaintext JSON → null (đúng hành vi)
        final result = SecurityService.decryptData(maliciousJson);
        expect(
          result,
          isNull,
          reason:
              'SecurityService đúng reject plaintext, '
              'nhưng BackupRepository vẫn bypass qua startsWith("{") check',
        );
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-007: Input cực lớn → OOM / timeout check
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-007: Encrypt/Decrypt dữ liệu lớn (1MB) → không OOM', () {
      final largePayload = 'A' * (1024 * 1024); // 1MB
      final encrypted = SecurityService.encryptData(largePayload);
      final decrypted = SecurityService.decryptData(encrypted);

      expect(decrypted, equals(largePayload));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-008: Cắt ngắn ciphertext
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-008: Truncated ciphertext → phải reject', () {
      final encrypted = SecurityService.encryptData(sampleJson);
      final parts = encrypted.split(':');

      // Cắt cipher còn 1/3
      final truncated =
          '${parts[0]}:${parts[1].substring(0, parts[1].length ~/ 3)}';
      final result = SecurityService.decryptData(truncated);

      expect(result, isNull, reason: 'Ciphertext bị cắt phải trả null');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-009: Base64 không hợp lệ
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-009: Invalid Base64 → phải reject, KHÔNG crash', () {
      final result = SecurityService.decryptData('!!!INVALID!!!:@#\$%^&*');
      expect(result, isNull);
    });

    test('TC-SEC-009b: Valid Base64 nhưng không phải AES → phải reject', () {
      final fakeIv = base64Encode(List.filled(16, 0));
      final fakeCipher = base64Encode(utf8.encode('this is not encrypted'));
      final result = SecurityService.decryptData('$fakeIv:$fakeCipher');
      expect(result, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // TC-SEC-010: Format ':' lồng nhau / giả mạo
    // ─────────────────────────────────────────────────────────────────────────
    test('TC-SEC-010: Multiple colons in input → phải handle gracefully', () {
      // Attacker craft string có nhiều ':'
      final result =
          SecurityService.decryptData('part1:part2:part3:part4');
      expect(result, isNull);
    });

    test('TC-SEC-010b: Colon at start → phải handle gracefully', () {
      final result = SecurityService.decryptData(':onlycipher');
      expect(result, isNull);
    });

    test('TC-SEC-010c: Colon at end → phải handle gracefully', () {
      final result = SecurityService.decryptData('onlyiv:');
      expect(result, isNull);
    });
  });
}

// ─── Utilities ─────────────────────────────────────────────────────────────────

/// Flip the first valid Base64 character to break the encoding.
String _flipBit(String base64Str) {
  if (base64Str.isEmpty) return base64Str;
  final chars = base64Str.split('');
  // Thay đổi ký tự đầu tiên
  final original = chars[0].codeUnitAt(0);
  chars[0] = String.fromCharCode((original + 1) % 128);
  return chars.join();
}
