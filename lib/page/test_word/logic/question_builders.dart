import 'dart:math';

import '../../../commons/enums.dart';
import '../../../database/app_db.dart';
import '../../../models/tag_vocab.dart';
import 'test_kind_question.dart';

/// What builders need besides the word: every word of the user (for wrong
/// choices) and the languages the device can read aloud.
class QuestionContext {
  QuestionContext({
    required this.allWords,
    required this.voiceLanguages,
  })  : _meanings = {
          for (final w in allWords)
            if (w.word.meaning.trim().isNotEmpty) w.word.meaning.trim(),
        },
        _words = {
          for (final w in allWords)
            if (w.word.word.trim().isNotEmpty) w.word.word.trim(),
        };

  final List<VocabularyWithTags> allWords;
  final Set<String> voiceLanguages;
  final Set<String> _meanings;
  final Set<String> _words;

  /// Distinct meanings that are not [word]'s own.
  int otherMeaningCount(VocabularyEntry word) =>
      _meanings.length - (_meanings.contains(word.meaning.trim()) ? 1 : 0);

  /// Distinct words that are not [word] itself.
  int otherWordCount(VocabularyEntry word) =>
      _words.length - (_words.contains(word.word.trim()) ? 1 : 0);
}

/// Up to [count] distinct, non-empty [candidates] that are not [correct].
List<String> pickDistractors({
  required String correct,
  required Iterable<String> candidates,
  required int count,
  required Random random,
}) {
  final right = correct.trim();
  final pool = candidates
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty && c != right)
      .toSet()
      .toList()
    ..shuffle(random);
  return pool.take(count).toList();
}

/// Builds the questions of one kind.
abstract class QuestionBuilder {
  const QuestionBuilder();

  TestKind get kind;

  bool canBuild(VocabularyWithTags word, QuestionContext context);

  /// Only called when [canBuild] is true.
  TestQuestion build(
    VocabularyWithTags word,
    QuestionContext context,
    Random random,
  );

  static QuestionBuilder of(TestKind kind) => switch (kind) {
        TestKind.choice => const ChoiceQuestionBuilder(),
        TestKind.typing => const TypingQuestionBuilder(),
        TestKind.listening => const ListeningQuestionBuilder(),
        TestKind.trueFalse => const TrueFalseQuestionBuilder(),
      };
}

class ChoiceQuestionBuilder extends QuestionBuilder {
  const ChoiceQuestionBuilder();

  @override
  TestKind get kind => TestKind.choice;

  @override
  bool canBuild(VocabularyWithTags word, QuestionContext context) =>
      context.otherMeaningCount(word.word) >= 3 &&
      context.otherWordCount(word.word) >= 3;

  @override
  TestQuestion build(
    VocabularyWithTags word,
    QuestionContext context,
    Random random,
  ) {
    final direction = random.nextBool()
        ? QuestionType.wordToMeaning
        : QuestionType.meaningToWord;
    String answerOf(VocabularyEntry e) =>
        direction == QuestionType.wordToMeaning ? e.meaning : e.word;

    final correct = answerOf(word.word).trim();
    final distractors = pickDistractors(
      correct: correct,
      candidates: context.allWords
          .where((w) => w.word.id != word.word.id)
          .map((w) => answerOf(w.word)),
      count: 3,
      random: random,
    );
    final choices = [correct, ...distractors]..shuffle(random);
    return ChoiceQuestion(
      word,
      direction: direction,
      choices: choices,
      correctIndex: choices.indexOf(correct),
    );
  }
}

class ListeningQuestionBuilder extends QuestionBuilder {
  const ListeningQuestionBuilder();

  @override
  TestKind get kind => TestKind.listening;

  @override
  bool canBuild(VocabularyWithTags word, QuestionContext context) {
    final language = word.word.language?.trim() ?? '';
    return language.isNotEmpty &&
        context.voiceLanguages.contains(language) &&
        word.word.word.trim().isNotEmpty &&
        context.otherMeaningCount(word.word) >= 3;
  }

  @override
  TestQuestion build(
    VocabularyWithTags word,
    QuestionContext context,
    Random random,
  ) {
    final correct = word.word.meaning.trim();
    final distractors = pickDistractors(
      correct: correct,
      candidates: context.allWords
          .where((w) => w.word.id != word.word.id)
          .map((w) => w.word.meaning),
      count: 3,
      random: random,
    );
    final choices = [correct, ...distractors]..shuffle(random);
    return ListeningQuestion(
      word,
      choices: choices,
      correctIndex: choices.indexOf(correct),
    );
  }
}

class TrueFalseQuestionBuilder extends QuestionBuilder {
  const TrueFalseQuestionBuilder();

  @override
  TestKind get kind => TestKind.trueFalse;

  @override
  bool canBuild(VocabularyWithTags word, QuestionContext context) =>
      context.otherMeaningCount(word.word) >= 1;

  @override
  TestQuestion build(
    VocabularyWithTags word,
    QuestionContext context,
    Random random,
  ) {
    final meaning = word.word.meaning.trim();
    final isMatch = random.nextBool();
    if (isMatch) {
      return TrueFalseQuestion(word, shownMeaning: meaning, isMatch: true);
    }
    final others = pickDistractors(
      correct: meaning,
      candidates: context.allWords
          .where((w) => w.word.id != word.word.id)
          .map((w) => w.word.meaning),
      count: 1,
      random: random,
    );
    // canBuild guarantees another meaning; fall back to a match if not.
    if (others.isEmpty) {
      return TrueFalseQuestion(word, shownMeaning: meaning, isMatch: true);
    }
    return TrueFalseQuestion(word, shownMeaning: others.first, isMatch: false);
  }
}

class TypingQuestionBuilder extends QuestionBuilder {
  const TypingQuestionBuilder();

  @override
  TestKind get kind => TestKind.typing;

  @override
  bool canBuild(VocabularyWithTags word, QuestionContext context) =>
      word.word.word.trim().isNotEmpty;

  @override
  TestQuestion build(
    VocabularyWithTags word,
    QuestionContext context,
    Random random,
  ) {
    final text = word.word.word.trim();
    final reading = word.word.pronunciation?.trim() ?? '';
    final useReading = word.word.language == 'ja' && reading.isNotEmpty;
    return TypingQuestion(
      word,
      accepted: [text, if (reading.isNotEmpty && reading != text) reading],
      hintAnswer: useReading ? reading : text,
    );
  }
}
