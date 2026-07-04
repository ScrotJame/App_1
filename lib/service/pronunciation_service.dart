import 'package:romanize/romanize.dart';
import 'package:kuromoji/kuromoji.dart';
import 'package:kana_kit/kana_kit.dart';

/// Service xử lý sinh phiên âm tự động cho từ vựng.
/// Chạy hoàn toàn offline — bundle dictionary data trong app.
class PronunciationService {
  /// Kuromoji tokenizer — dùng dynamic vì Tokenizer class nằm trong src/
  dynamic _japaneseTokenizer;
  final _kanaKit = const KanaKit();

  /// Các ngôn ngữ hỗ trợ auto-pronunciation
  static const _supportedLanguages = {'ja', 'zh', 'ko', 'ru', 'ar', 'he'};

  /// Khởi tạo dictionary (nặng, nên gọi 1 lần khi app start).
  /// Bao gồm: Japanese tokenizer (kuromoji), Chinese pinyin dict.
  Future<void> ensureInitialized() async {
    await TextRomanizer.ensureInitialized();
    _japaneseTokenizer = await TokenizerBuilder().build();
  }

  /// Kiểm tra ngôn ngữ có hỗ trợ auto-pronunciation không
  bool isLanguageSupported(String? languageCode) {
    if (languageCode == null) return false;
    return _supportedLanguages.contains(languageCode);
  }

  /// Validate: text có chứa ký tự phù hợp với ngôn ngữ được chỉ định không.
  /// Trả false nếu user set sai ngôn ngữ so với ký tự thực tế.
  bool _isTextMatchingLanguage(String text, String languageCode) {
    switch (languageCode) {
      case 'ja':
        // Tiếng Nhật: chứa Hiragana, Katakana, hoặc CJK
        return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]')
            .hasMatch(text);
      case 'zh':
        // Tiếng Trung: chứa CJK nhưng KHÔNG chứa Hiragana/Katakana
        return RegExp(r'[\u4E00-\u9FFF]').hasMatch(text) &&
            !RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(text);
      case 'ko':
        // Tiếng Hàn: chứa Hangul
        return RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]')
            .hasMatch(text);
      case 'ru':
        // Cyrillic
        return RegExp(r'[\u0400-\u04FF]').hasMatch(text);
      case 'ar':
        // Arabic
        return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      case 'he':
        // Hebrew
        return RegExp(r'[\u0590-\u05FF]').hasMatch(text);
      default:
        return false;
    }
  }

  /// Sinh phiên âm dựa trên text + language code.
  ///
  /// - `ja` → Hiragana (via kuromoji + kana_kit)
  /// - `zh` → Pinyin có dấu thanh (via ChineseRomanizer)
  /// - `ko` → Romanization (via KoreanRomanizer)
  /// - `ru`, `ar`, `he` → Romanization tương ứng
  ///
  /// Trả về `null` nếu:
  /// - Language không hỗ trợ (en, vi, fr, de, es, th...)
  /// - Text không khớp với ngôn ngữ đã chỉ định
  Future<String?> generatePronunciation(
      String text, String? languageCode) async {
    if (text.trim().isEmpty) return null;
    if (languageCode == null) return null;
    if (!isLanguageSupported(languageCode)) return null;

    // Guard: validate text khớp với ngôn ngữ
    if (!_isTextMatchingLanguage(text.trim(), languageCode)) return null;

    try {
      switch (languageCode) {
        case 'ja':
          return _generateJapaneseHiragana(text.trim());
        case 'zh':
          return _generateChinesePinyin(text.trim());
        default:
          return _generateRomanization(text.trim(), languageCode);
      }
    } catch (e) {
      // Fallback: trả null nếu có lỗi, không crash app
      return null;
    }
  }

  /// Tiếng Nhật: Kanji → Hiragana
  /// Sử dụng kuromoji tokenizer để lấy reading (Katakana),
  /// rồi convert sang Hiragana bằng kana_kit.
  String? _generateJapaneseHiragana(String text) {
    if (_japaneseTokenizer == null) return null;

    final List<Map<String, dynamic>> tokens =
        (_japaneseTokenizer.tokenize(text) as List).cast<Map<String, dynamic>>();
    final buffer = StringBuffer();

    for (final token in tokens) {
      final reading = token['reading'] as String?;
      final surfaceForm = token['surface_form'] as String? ?? '';

      if (reading != null && reading != '*' && reading.isNotEmpty) {
        // Reading từ kuromoji là Katakana → convert sang Hiragana
        buffer.write(_kanaKit.toHiragana(reading));
      } else {
        // Không có reading (dấu câu, số, v.v.) → giữ nguyên
        buffer.write(surfaceForm);
      }
    }

    final result = buffer.toString();
    // Nếu kết quả giống text gốc → không cần phiên âm
    if (result == text) return null;
    return result.isNotEmpty ? result : null;
  }

  /// Tiếng Trung: Hanzi → Pinyin có dấu thanh
  String? _generateChinesePinyin(String text) {
    final romanizer =
        ChineseRomanizer(toneAnnotation: ToneAnnotation.mark);
    final result = romanizer.romanize(text);
    if (result.trim().isEmpty || result.trim() == text.trim()) return null;
    return result.trim();
  }

  /// Các ngôn ngữ khác: dùng TextRomanizer theo language name
  String? _generateRomanization(String text, String languageCode) {
    final langName = _mapLanguageCode(languageCode);
    if (langName == null) return null;

    final romanizer = TextRomanizer.forLanguageOrNull(langName);
    if (romanizer == null) return null;

    final result = romanizer.romanize(text);
    if (result.trim().isEmpty || result.trim() == text.trim()) return null;
    return result.trim();
  }

  /// Map language code (ISO 639-1) sang tên ngôn ngữ của package romanize
  String? _mapLanguageCode(String code) {
    const mapping = {
      'ko': 'korean',
      'ru': 'cyrillic',
      'ar': 'arabic',
      'he': 'hebrew',
    };
    return mapping[code];
  }
}

