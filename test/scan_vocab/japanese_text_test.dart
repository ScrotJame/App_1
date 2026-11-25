import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/scan_vocab/logic/japanese_text.dart';

void main() {
  test('nhận biết kanji và kana', () {
    expect(containsHan('食べる'), isTrue);
    expect(containsHan('時々'), isTrue);
    expect(containsHan('コーヒー'), isFalse);
    expect(containsKana('コーヒー'), isTrue);
    expect(containsKana('学生'), isFalse);
    expect(containsKana('・'), isFalse);
  });

  test('stripBrackets và hasBrackets', () {
    expect(stripBrackets('（たべる）'), 'たべる');
    expect(stripBrackets('( たべる )'), 'たべる');
    expect(stripBrackets('（'), '');
    expect(hasBrackets('(a)'), isTrue);
    expect(hasBrackets('abc'), isFalse);
  });

  test('isHiraganaReading', () {
    expect(isHiraganaReading('たべる'), isTrue);
    expect(isHiraganaReading('（たべる）'), isTrue);
    expect(isHiraganaReading('食べる'), isFalse);
    expect(isHiraganaReading('コーヒー'), isFalse);
    expect(isHiraganaReading('（）'), isFalse);
    expect(isHiraganaReading('ー'), isFalse);
  });

  group('splitBracketReading', () {
    test('ngoặc toàn độ rộng và ngoặc ASCII', () {
      expect(splitBracketReading('食べる（たべる）'),
          (word: '食べる', reading: 'たべる'));
      expect(splitBracketReading('珈琲 (コーヒー)'),
          (word: '珈琲', reading: 'コーヒー'));
    });

    test('không tách khi trong ngoặc không phải toàn kana', () {
      expect(splitBracketReading('go (went)'), isNull);
      expect(splitBracketReading('食べる（ăn）'), isNull);
    });

    test('không tách khi thiếu phần từ hoặc không có ngoặc', () {
      expect(splitBracketReading('（たべる）'), isNull);
      expect(splitBracketReading('食べる'), isNull);
      expect(splitBracketReading('食べる（たべる）です'), isNull);
    });
  });

  group('resolveLanguage', () {
    test('có kana là ja', () {
      expect(resolveLanguage('食べる', 'zh'), 'ja');
      expect(resolveLanguage('ねこ', null), 'ja');
    });

    test('chỉ kanji: zh hoặc không rõ là ja', () {
      expect(resolveLanguage('学生', 'zh'), 'ja');
      expect(resolveLanguage('猫', null), 'ja');
      expect(resolveLanguage('学生', 'ko'), 'ko');
    });

    test('chữ khác giữ kết quả nhận diện', () {
      expect(resolveLanguage('cat', 'en'), 'en');
      expect(resolveLanguage('cat', null), isNull);
    });
  });
}
