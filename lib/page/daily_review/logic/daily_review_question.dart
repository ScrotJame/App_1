import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../commons/enums.dart';
import '../../../database/app_db.dart';

/// A word ↔ meaning multiple-choice question.
class DailyReviewQuestion extends Equatable {
  const DailyReviewQuestion({
    required this.word,
    required this.type,
    required this.choices,
    required this.correctIndex,
  });

  final VocabularyEntry word;

  /// [QuestionType.wordToMeaning] or [QuestionType.meaningToWord].
  final QuestionType type;
  final List<String> choices;
  final int correctIndex;

  bool get asksMeaning => type == QuestionType.wordToMeaning;

  String get prompt => asksMeaning ? word.word : word.meaning;

  /// Shown only when the word itself is the prompt.
  String get pronunciation => asksMeaning ? (word.pronunciation ?? '') : '';

  /// Distractors come from the whole [pool], like in Test. A small pool gives
  /// fewer than 4 choices.
  static DailyReviewQuestion build(
    VocabularyEntry word,
    List<VocabularyEntry> pool,
    Random random,
  ) {
    final type = random.nextBool()
        ? QuestionType.wordToMeaning
        : QuestionType.meaningToWord;
    String answerOf(VocabularyEntry entry) =>
        type == QuestionType.wordToMeaning ? entry.meaning : entry.word;

    final correct = answerOf(word);
    final others = pool.where((entry) => entry.id != word.id).toList()
      ..shuffle(random);
    final distractors = <String>{};
    for (final entry in others) {
      final answer = answerOf(entry);
      if (answer == correct || answer.trim().isEmpty) continue;
      distractors.add(answer);
      if (distractors.length == 3) break;
    }

    final choices = [correct, ...distractors]..shuffle(random);
    return DailyReviewQuestion(
      word: word,
      type: type,
      choices: choices,
      correctIndex: choices.indexOf(correct),
    );
  }

  @override
  List<Object?> get props => [word, type, choices, correctIndex];
}
