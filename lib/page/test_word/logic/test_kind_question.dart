import 'package:equatable/equatable.dart';

import '../../../commons/enums.dart';
import '../../../database/app_db.dart';
import '../../../models/tag_vocab.dart';
import 'answer_normalizer.dart';
import 'test_answer.dart';

/// One question of a Test. Each kind has its own subclass.
sealed class TestQuestion extends Equatable {
  const TestQuestion(this.word);

  final VocabularyWithTags word;

  VocabularyEntry get entry => word.word;

  TestKind get kind;

  /// Whether [answer] is right. [TimedOut] and an answer of another kind
  /// are always wrong.
  bool grade(TestAnswer answer);
}

/// A question answered by tapping one of [choices].
sealed class MultipleChoiceQuestion extends TestQuestion {
  const MultipleChoiceQuestion(
    super.word, {
    required this.choices,
    required this.correctIndex,
  });

  final List<String> choices;
  final int correctIndex;

  String get correctChoice => choices[correctIndex];

  @override
  bool grade(TestAnswer answer) =>
      answer is ChoiceAnswer && answer.index == correctIndex;
}

/// Word → meaning or meaning → word, picked from 4 choices.
class ChoiceQuestion extends MultipleChoiceQuestion {
  const ChoiceQuestion(
    super.word, {
    required this.direction,
    required super.choices,
    required super.correctIndex,
  });

  /// [QuestionType.wordToMeaning] or [QuestionType.meaningToWord].
  final QuestionType direction;

  bool get asksMeaning => direction == QuestionType.wordToMeaning;

  String get prompt => asksMeaning ? entry.word : entry.meaning;

  /// Only shown when the word itself is the prompt.
  String get pronunciation => asksMeaning ? (entry.pronunciation ?? '') : '';

  @override
  TestKind get kind => TestKind.choice;

  @override
  List<Object?> get props => [entry, direction, choices, correctIndex];
}

/// The word is read aloud; the user picks its meaning.
class ListeningQuestion extends MultipleChoiceQuestion {
  const ListeningQuestion(
    super.word, {
    required super.choices,
    required super.correctIndex,
  });

  String get spokenText => entry.word;

  String? get language => entry.language;

  @override
  TestKind get kind => TestKind.listening;

  @override
  List<Object?> get props => [entry, choices, correctIndex];
}

/// The word with a meaning that is right or not.
class TrueFalseQuestion extends TestQuestion {
  const TrueFalseQuestion(
    super.word, {
    required this.shownMeaning,
    required this.isMatch,
  });

  final String shownMeaning;

  /// Whether [shownMeaning] is the word's own meaning.
  final bool isMatch;

  @override
  TestKind get kind => TestKind.trueFalse;

  @override
  bool grade(TestAnswer answer) =>
      answer is BoolAnswer && answer.value == isMatch;

  @override
  List<Object?> get props => [entry, shownMeaning, isMatch];
}

/// The meaning is shown; the user types the word.
class TypingQuestion extends TestQuestion {
  const TypingQuestion(
    super.word, {
    required this.accepted,
    required this.hintAnswer,
  });

  /// The word and, when there is one, its reading.
  final List<String> accepted;

  /// What hints reveal, one character at a time.
  final String hintAnswer;

  String get prompt => entry.meaning;

  String? get language => entry.language;

  int get hintLength => hintAnswer.runes.length;

  /// The first [revealed] characters of [hintAnswer], the rest as "_".
  String hintMask(int revealed) {
    final chars = hintAnswer.runes.map(String.fromCharCode).toList();
    return [
      for (var i = 0; i < chars.length; i++) i < revealed ? chars[i] : '_',
    ].join(' ');
  }

  @override
  TestKind get kind => TestKind.typing;

  @override
  bool grade(TestAnswer answer) =>
      answer is TextAnswer &&
      AnswerNormalizer.matches(answer.text, accepted, language: language);

  @override
  List<Object?> get props => [entry, accepted, hintAnswer];
}
