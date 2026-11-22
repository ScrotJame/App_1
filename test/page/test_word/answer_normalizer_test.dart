import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/test_word/logic/answer_normalizer.dart';

void main() {
  group('normalize', () {
    test('trims, joins spaces and lowercases', () {
      expect(AnswerNormalizer.normalize('  Good   Morning '), 'good morning');
    });

    test('drops punctuation at both ends', () {
      expect(AnswerNormalizer.normalize('cat!'), 'cat');
      expect(AnswerNormalizer.normalize('...cat?'), 'cat');
      expect(AnswerNormalizer.normalize('ねこ。', language: 'ja'), 'ねこ');
    });

    test('Japanese: romaji and katakana become hiragana', () {
      expect(AnswerNormalizer.normalize('taberu', language: 'ja'), 'たべる');
      expect(AnswerNormalizer.normalize('タベル', language: 'ja'), 'たべる');
      expect(AnswerNormalizer.normalize(' Taberu ', language: 'ja'), 'たべる');
    });

    test('Japanese: kanji stays as it is', () {
      expect(AnswerNormalizer.normalize('食べる', language: 'ja'), '食べる');
    });

    test('other languages keep their letters', () {
      expect(AnswerNormalizer.normalize('neko', language: 'en'), 'neko');
    });
  });

  group('matches', () {
    const accepted = ['食べる', 'たべる'];

    test('the word or its reading, in any script, is right', () {
      for (final input in ['食べる', 'たべる', 'タベル', 'taberu', ' Taberu ']) {
        expect(
          AnswerNormalizer.matches(input, accepted, language: 'ja'),
          isTrue,
          reason: input,
        );
      }
    });

    test('a different or partial answer is wrong', () {
      expect(AnswerNormalizer.matches('たべ', accepted, language: 'ja'), isFalse);
      expect(AnswerNormalizer.matches('nomu', accepted, language: 'ja'),
          isFalse);
    });

    test('an empty answer is always wrong', () {
      expect(AnswerNormalizer.matches('', ['a']), isFalse);
      expect(AnswerNormalizer.matches('   ', ['a']), isFalse);
      expect(AnswerNormalizer.matches('!', ['!']), isFalse);
    });

    test('case does not matter outside Japanese', () {
      expect(AnswerNormalizer.matches('Apple', ['apple'], language: 'en'),
          isTrue);
    });

    test('romaji is not read as kana outside Japanese', () {
      expect(AnswerNormalizer.matches('neko', ['ねこ'], language: 'en'),
          isFalse);
    });
  });
}
