import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/tag_vocab.dart';
import 'package:test_abc/page/test_word/logic/test_answer.dart';
import 'package:test_abc/page/test_word/logic/test_kind_question.dart';

/// A word built in memory, for tests that do not need the database.
VocabularyWithTags entry(
  int id,
  String word,
  String meaning, {
  String? pronunciation,
  String? language,
  int level = 0,
  List<int> tagIds = const [],
}) {
  final at = DateTime(2026, 1, 1);
  return VocabularyWithTags(
    word: VocabularyEntry(
      id: id,
      word: word,
      meaning: meaning,
      pronunciation: pronunciation,
      language: language,
      level: level,
      correctCount: 0,
      wrongCount: 0,
      easeFactor: 2.5,
      repetitions: 0,
      interval: 0,
      createdAt: at,
      updatedAt: at,
    ),
    tags: [
      for (final tagId in tagIds)
        Tag(id: tagId, tagName: 'tag $tagId', createdAt: at, updatedAt: at),
    ],
  );
}

/// The right answer to [question].
TestAnswer correctAnswerFor(TestQuestion question) => switch (question) {
      final MultipleChoiceQuestion q => ChoiceAnswer(q.correctIndex),
      final TrueFalseQuestion q => BoolAnswer(q.isMatch),
      final TypingQuestion q => TextAnswer(q.accepted.first),
    };

/// A wrong answer to [question].
TestAnswer wrongAnswerFor(TestQuestion question) => switch (question) {
      final MultipleChoiceQuestion q =>
        ChoiceAnswer((q.correctIndex + 1) % q.choices.length),
      final TrueFalseQuestion q => BoolAnswer(!q.isMatch),
      TypingQuestion() => const TextAnswer('###'),
    };
