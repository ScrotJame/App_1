import 'package:equatable/equatable.dart';

class AnswerOption extends Equatable {
  final String id;
  final String text;
  final bool isCorrect;

  const AnswerOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [id, text, isCorrect];
}

class QuizQuestion extends Equatable {
  final String word;
  final String? pronunciation;
  final String? imageUrl;
  final String questionText;
  final List<AnswerOption> options;

  const QuizQuestion({
    required this.word,
    this.pronunciation,
    this.imageUrl,
    required this.questionText,
    required this.options,
  });

  @override
  List<Object?> get props => [word, pronunciation, imageUrl, questionText, options];
}
