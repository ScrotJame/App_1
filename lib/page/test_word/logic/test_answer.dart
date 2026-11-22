import 'package:equatable/equatable.dart';

/// What the user gave for one question.
sealed class TestAnswer extends Equatable {
  const TestAnswer();
}

/// A tap on one of the choices.
class ChoiceAnswer extends TestAnswer {
  const ChoiceAnswer(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// "True" or "False".
class BoolAnswer extends TestAnswer {
  const BoolAnswer(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

/// A typed answer. Empty when the user did not remember.
class TextAnswer extends TestAnswer {
  const TextAnswer(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The time ran out before an answer. Always wrong.
class TimedOut extends TestAnswer {
  const TimedOut();

  @override
  List<Object?> get props => [];
}
