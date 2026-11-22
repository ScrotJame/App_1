import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/models/tag_vocab.dart';
import 'package:test_abc/page/test_word/logic/question_builders.dart';
import 'package:test_abc/page/test_word/logic/test_answer.dart';
import 'package:test_abc/page/test_word/logic/test_kind_question.dart';

import 'test_word_support.dart';

void main() {
  final words = [
    entry(1, '猫', 'cat', pronunciation: 'ねこ', language: 'ja'),
    entry(2, '犬', 'dog', pronunciation: 'いぬ', language: 'ja'),
    entry(3, '鳥', 'bird', language: 'ja'),
    entry(4, '魚', 'fish', language: 'ja'),
    entry(5, 'apple', 'táo', language: 'en'),
  ];
  final cat = words.first;

  QuestionContext contextOf(
    List<VocabularyWithTags> pool, {
    Set<String> voices = const {'ja'},
  }) =>
      QuestionContext(allWords: pool, voiceLanguages: voices);

  group('multiple choice', () {
    const builder = ChoiceQuestionBuilder();

    test('the answer is among 4 distinct choices, in both directions', () {
      final directions = <QuestionType>{};
      for (var seed = 0; seed < 30; seed++) {
        final q =
            builder.build(cat, contextOf(words), Random(seed)) as ChoiceQuestion;
        directions.add(q.direction);

        expect(q.choices, hasLength(4));
        expect(q.choices.toSet(), hasLength(4));
        expect(q.correctChoice, q.asksMeaning ? 'cat' : '猫');
        expect(q.prompt, q.asksMeaning ? '猫' : 'cat');
        expect(q.pronunciation, q.asksMeaning ? 'ねこ' : '');
      }
      expect(directions, {QuestionType.wordToMeaning, QuestionType.meaningToWord});
    });

    test('grades a choice index', () {
      final q = builder.build(cat, contextOf(words), Random(1));
      expect(q.grade(correctAnswerFor(q)), isTrue);
      expect(q.grade(wrongAnswerFor(q)), isFalse);
      expect(q.grade(const TimedOut()), isFalse);
      expect(q.grade(const BoolAnswer(true)), isFalse);
    });

    test('needs 3 other meanings and 3 other words', () {
      expect(builder.canBuild(cat, contextOf(words)), isTrue);
      expect(builder.canBuild(cat, contextOf(words.take(3).toList())), isFalse);
    });

    test('a word sharing the meaning is never a second right answer', () {
      final pool = [...words, entry(6, 'ネコ', 'cat')];
      for (var seed = 0; seed < 30; seed++) {
        final q =
            builder.build(cat, contextOf(pool), Random(seed)) as ChoiceQuestion;
        if (q.asksMeaning) {
          expect(q.choices.where((c) => c == 'cat'), hasLength(1));
        }
      }
    });
  });

  group('listening', () {
    const builder = ListeningQuestionBuilder();

    test('reads the word and offers 4 meanings', () {
      final q = builder.build(cat, contextOf(words), Random(2))
          as ListeningQuestion;

      expect(q.spokenText, '猫');
      expect(q.language, 'ja');
      expect(q.choices, hasLength(4));
      expect(q.correctChoice, 'cat');
      expect(q.grade(ChoiceAnswer(q.correctIndex)), isTrue);
    });

    test('needs a language with a voice', () {
      expect(builder.canBuild(cat, contextOf(words)), isTrue);
      expect(builder.canBuild(cat, contextOf(words, voices: {})), isFalse);
      expect(builder.canBuild(words[4], contextOf(words)), isFalse);
      expect(
        builder.canBuild(entry(7, 'x', 'y'), contextOf([...words, entry(7, 'x', 'y')])),
        isFalse,
      );
    });
  });

  group('true / false', () {
    const builder = TrueFalseQuestionBuilder();

    test('shows the right meaning or another word\'s meaning', () {
      final matches = <bool>{};
      for (var seed = 0; seed < 30; seed++) {
        final q = builder.build(cat, contextOf(words), Random(seed))
            as TrueFalseQuestion;
        matches.add(q.isMatch);
        if (q.isMatch) {
          expect(q.shownMeaning, 'cat');
        } else {
          expect(q.shownMeaning, isNot('cat'));
          expect(words.map((w) => w.word.meaning), contains(q.shownMeaning));
        }
        expect(q.grade(BoolAnswer(q.isMatch)), isTrue);
        expect(q.grade(BoolAnswer(!q.isMatch)), isFalse);
      }
      expect(matches, {true, false});
    });

    test('needs at least one other meaning', () {
      expect(builder.canBuild(cat, contextOf([cat])), isFalse);
      expect(builder.canBuild(cat, contextOf(words.take(2).toList())), isTrue);
    });
  });

  group('typing', () {
    const builder = TypingQuestionBuilder();

    test('accepts the word and its reading', () {
      final q = builder.build(cat, contextOf(words), Random(3)) as TypingQuestion;

      expect(q.prompt, 'cat');
      expect(q.accepted, ['猫', 'ねこ']);
      expect(q.grade(const TextAnswer('猫')), isTrue);
      expect(q.grade(const TextAnswer('neko')), isTrue);
      expect(q.grade(const TextAnswer('ネコ')), isTrue);
      expect(q.grade(const TextAnswer('inu')), isFalse);
      expect(q.grade(const TextAnswer('')), isFalse);
    });

    test('hints reveal the reading of a Japanese word', () {
      final q = builder.build(cat, contextOf(words), Random(3)) as TypingQuestion;

      expect(q.hintAnswer, 'ねこ');
      expect(q.hintLength, 2);
      expect(q.hintMask(0), '_ _');
      expect(q.hintMask(1), 'ね _');
      expect(q.hintMask(2), 'ね こ');
    });

    test('hints reveal the word itself otherwise', () {
      final q = builder.build(words[4], contextOf(words), Random(3))
          as TypingQuestion;

      expect(q.accepted, ['apple']);
      expect(q.hintAnswer, 'apple');
    });

    test('can always be built from a word', () {
      expect(builder.canBuild(cat, contextOf([cat])), isTrue);
    });
  });

  test('QuestionBuilder.of returns the builder of each kind', () {
    for (final kind in TestKind.values) {
      expect(QuestionBuilder.of(kind).kind, kind);
    }
  });
}
