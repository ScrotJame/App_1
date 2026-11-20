import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/daily_review/logic/daily_review_question.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../repository/backup_test_support.dart';

void main() {
  late AppDatabase db;
  late List<VocabularyEntry> words;

  setUp(() async {
    db = await openDbWithUser('device');
    addTearDown(db.close);
    final vocabulary = VocabularyRepository(db);
    for (final (word, meaning) in [
      ('猫', 'cat'),
      ('犬', 'dog'),
      ('鳥', 'bird'),
      ('魚', 'fish'),
      ('馬', 'horse'),
    ]) {
      await vocabulary.insertWord(word: word, meaning: meaning);
    }
    words = await vocabulary.getAllWords();
  });

  test('the answer is among up to 4 distinct choices', () {
    for (var seed = 0; seed < 30; seed++) {
      final question =
          DailyReviewQuestion.build(words.first, words, Random(seed));
      final answer = question.type == QuestionType.wordToMeaning
          ? words.first.meaning
          : words.first.word;

      expect(question.choices, hasLength(4));
      expect(question.choices.toSet(), hasLength(4));
      expect(question.choices[question.correctIndex], answer);
      expect(
        question.prompt,
        question.type == QuestionType.wordToMeaning
            ? words.first.word
            : words.first.meaning,
      );
    }
  });

  test('a pool of one word gives a single choice', () {
    final question =
        DailyReviewQuestion.build(words.first, [words.first], Random(1));
    expect(question.choices, hasLength(1));
    expect(question.correctIndex, 0);
  });
}
