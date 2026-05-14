import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SecurityService {
  static final String _envKey =
      dotenv.env['BACKUP_SECRET_KEY'] ?? '';

  static final _key =
  enc.Key.fromUtf8(_envKey.padRight(32, '0').substring(0, 32));

  static final _legacyIv = enc.IV.fromLength(16);
  static final _encrypter = enc.Encrypter(enc.AES(_key));

  /// Mã hóa
  static String encryptData(String rawJson) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(rawJson, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Giải mã
  static String? decryptData(String encryptedBase64) {
    final clean = encryptedBase64.replaceAll(RegExp(r'\s+'), '');

    if (clean.contains(':')) {
      try {
        final colonIndex = clean.indexOf(':');
        final ivBase64 = clean.substring(0, colonIndex);
        final cipherBase64 = clean.substring(colonIndex + 1);
        final iv = enc.IV.fromBase64(ivBase64);
        return _encrypter.decrypt64(cipherBase64, iv: iv);
      } catch (e) {
        print('❌ CBC decrypt failed: $e'); // <-- thêm dòng này
      }
    }

    try {
      return _encrypter.decrypt64(clean, iv: _legacyIv);
    } catch (e) {
      print('❌ Legacy decrypt failed: $e'); // <-- thêm dòng này
      return null;
    }
  }
}