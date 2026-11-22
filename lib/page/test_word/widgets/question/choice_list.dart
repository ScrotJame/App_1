import 'package:flutter/material.dart';

import '../../logic/test_answer.dart';
import '../../logic/test_kind_question.dart';
import 'choice_tile.dart';

/// The choices of a multiple-choice or listening question.
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.question,
    required this.answer,
    required this.eliminated,
    required this.onSelect,
  });

  final MultipleChoiceQuestion question;
  final TestAnswer? answer;
  final List<int> eliminated;
  final ValueChanged<int> onSelect;

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final current = answer;
    final answered = current != null;
    final picked = current is ChoiceAnswer ? current.index : null;
    return Column(
      children: [
        for (var i = 0; i < question.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChoiceTile(
              label: i < _labels.length ? _labels[i] : '${i + 1}',
              text: question.choices[i],
              state: _stateOf(i, answered, picked),
              onTap: answered || eliminated.contains(i)
                  ? null
                  : () => onSelect(i),
            ),
          ),
      ],
    );
  }

  ChoiceTileState _stateOf(int i, bool answered, int? picked) {
    if (answered && i == question.correctIndex) return ChoiceTileState.correct;
    if (answered && i == picked) return ChoiceTileState.wrong;
    if (eliminated.contains(i)) return ChoiceTileState.eliminated;
    return ChoiceTileState.idle;
  }
}
