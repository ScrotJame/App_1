import 'package:flutter/material.dart';

import '../../../../generated/l10n.dart';
import '../../logic/test_answer.dart';
import '../../logic/test_kind_question.dart';
import 'choice_list.dart';
import 'question_card.dart';

class ChoiceQuestionView extends StatelessWidget {
  const ChoiceQuestionView({
    super.key,
    required this.question,
    required this.answer,
    required this.eliminated,
    required this.onSelect,
  });

  final ChoiceQuestion question;
  final TestAnswer? answer;
  final List<int> eliminated;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionCard(
          label: question.asksMeaning ? s.fieldVocabulary : s.fieldMeaning,
          text: question.prompt,
          subtitle: question.pronunciation,
        ),
        const SizedBox(height: 10),
        QuestionPrompt(
          question.asksMeaning
              ? s.test_question_word_to_meaning
              : s.test_question_meaning_to_word,
        ),
        const SizedBox(height: 14),
        ChoiceList(
          question: question,
          answer: answer,
          eliminated: eliminated,
          onSelect: onSelect,
        ),
      ],
    );
  }
}
