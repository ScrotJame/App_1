/// Luật chữ Nhật dùng cho màn quét. Dart thuần.
library;

final RegExp _han =
    RegExp(r'[々㐀-䶿一-鿿豈-﫿]');
final RegExp _kana =
    RegExp(r'[ぁ-ゖァ-ヺー-ヿｦ-ﾟ]');
final RegExp _hiragana = RegExp(r'[ぁ-ゖ]');
final RegExp _readingOnly = RegExp(r'^[ぁ-ゟ・ー\s]+$');
final RegExp _brackets = RegExp(r'[（()）\[\]［］【】]');
final RegExp _bracketReading = RegExp(
    r'^(.+?)\s*[（(]\s*([ぁ-ゖゝゞァ-ヺ・ー\s]+?)\s*[）)]$');

bool containsHan(String text) => _han.hasMatch(text);

bool containsKana(String text) => _kana.hasMatch(text);

bool hasBrackets(String text) => _brackets.hasMatch(text);

String stripBrackets(String text) => text.replaceAll(_brackets, '').trim();

/// `true` khi chữ (bỏ ngoặc) chỉ gồm hiragana, tức là một cách đọc.
bool isHiraganaReading(String text) {
  final bare = stripBrackets(text);
  return _hiragana.hasMatch(bare) && _readingOnly.hasMatch(bare);
}

/// Tách `X（かな）` thành từ và cách đọc; null khi không đúng mẫu.
({String word, String reading})? splitBracketReading(String text) {
  final match = _bracketReading.firstMatch(text.trim());
  if (match == null) return null;
  final word = (match.group(1) ?? '').trim();
  final reading = (match.group(2) ?? '').trim();
  if (word.isEmpty || reading.isEmpty) return null;
  return (word: word, reading: reading);
}

/// Mã ngôn ngữ cuối cùng của [text] khi người dùng chưa chọn tay.
/// Có kana là `ja`; chỉ có kanji mà nhận diện ra `zh` hoặc không rõ cũng là `ja`.
String? resolveLanguage(String text, String? detected) {
  if (containsKana(text)) return 'ja';
  if (containsHan(text) && (detected == null || detected == 'zh')) return 'ja';
  return detected;
}
