/// Nối các mảnh chữ OCR theo thứ tự đã cho.
///
/// Hai mảnh kề nhau được nối liền khi ký tự cuối của mảnh trước và ký tự đầu
/// của mảnh sau đều là chữ viết không dùng dấu cách (Hán, kana, dấu câu /
/// ký tự toàn độ rộng CJK) — vd. "食べ" + "物" → "食べ物". Các trường hợp còn lại
/// (Latin, tiếng Việt, Hangul, hoặc một phía là Latin) nối bằng một dấu cách.
/// Mảnh rỗng bị bỏ qua.
String joinOcrTokens(Iterable<String> tokens) {
  final buffer = StringBuffer();
  int? lastRune;
  for (final raw in tokens) {
    final token = raw.trim();
    if (token.isEmpty) continue;
    final firstRune = token.runes.first;
    if (lastRune != null) {
      if (!(isNoSpaceScriptRune(lastRune) && isNoSpaceScriptRune(firstRune))) {
        buffer.write(' ');
      }
    }
    buffer.write(token);
    lastRune = token.runes.last;
  }
  return buffer.toString();
}

/// `true` cho ký tự thuộc hệ chữ không ngăn từ bằng dấu cách (Trung / Nhật).
/// Hangul cố ý không tính vì tiếng Hàn có dấu cách giữa các từ.
bool isNoSpaceScriptRune(int rune) {
  return (rune >= 0x2E80 && rune <= 0x2FDF) || // CJK Radicals, Kangxi Radicals
      (rune >= 0x3000 && rune <= 0x303F) || // CJK Symbols & Punctuation
      (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana, Katakana
      (rune >= 0x31C0 && rune <= 0x31FF) || // CJK Strokes, Katakana Ext
      (rune >= 0x3190 && rune <= 0x319F) || // Kanbun
      (rune >= 0x3200 && rune <= 0x33FF) || // Enclosed CJK, CJK Compatibility
      (rune >= 0x3400 && rune <= 0x4DBF) || // CJK Ext A
      (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK Unified Ideographs
      (rune >= 0xF900 && rune <= 0xFAFF) || // CJK Compatibility Ideographs
      (rune >= 0xFE30 && rune <= 0xFE4F) || // CJK Compatibility Forms
      (rune >= 0xFF00 && rune <= 0xFF9F) || // Fullwidth ASCII, halfwidth katakana
      (rune >= 0xFFE0 && rune <= 0xFFEF) || // Fullwidth symbols (bỏ qua Hangul nửa độ rộng)
      (rune >= 0x20000 && rune <= 0x3134F); // CJK Ext B–G (ngoài BMP)
}
