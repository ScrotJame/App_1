import 'package:kana_kit/kana_kit.dart';

/// Makes a typed answer and the expected one comparable.
class AnswerNormalizer {
  AnswerNormalizer._();

  static const _kanaKit = KanaKit();
  static final _spaces = RegExp(r'\s+');
  static final _edgePunctuation =
      RegExp(r'^[.,!?;:。、！？；：・]+|[.,!?;:。、！？；：・]+$');

  /// Trimmed, single-spaced, lowercase, without punctuation at the ends.
  /// For Japanese, romaji and katakana become hiragana; kanji stays.
  static String normalize(String input, {String? language}) {
    var text = input.trim().replaceAll(_spaces, ' ').toLowerCase();
    text = text.replaceAll(_edgePunctuation, '').trim();
    if (text.isEmpty) return text;
    if (language == 'ja') text = _kanaKit.toHiragana(text);
    return text;
  }

  /// Whether [input] is one of [accepted] once both are normalized. An empty
  /// answer never matches.
  static bool matches(
    String input,
    Iterable<String> accepted, {
    String? language,
  }) {
    final given = normalize(input, language: language);
    if (given.isEmpty) return false;
    return accepted.any((a) => normalize(a, language: language) == given);
  }
}
