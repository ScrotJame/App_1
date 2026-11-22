import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../commons/enums.dart';
import '../../../models/tag_vocab.dart';
import 'question_builders.dart';
import 'test_kind_question.dart';

/// A selected kind that got no question.
class TestPlanWarning extends Equatable {
  const TestPlanWarning(this.kind, {this.missingVoiceLanguages = const []});

  final TestKind kind;

  /// For [TestKind.listening]: languages of the pool without a voice.
  final List<String> missingVoiceLanguages;

  @override
  List<Object?> get props => [kind, missingVoiceLanguages];
}

class TestPlan {
  const TestPlan({required this.questions, required this.warnings});

  final List<TestQuestion> questions;
  final List<TestPlanWarning> warnings;
}

/// Picks the words of a test and the kind of each question.
class TestPlanner {
  TestPlanner._();

  /// Each word gets at most one question, of the selected kind that has the
  /// fewest questions so far among the kinds the word can be used for (ties
  /// are random). A word no selected kind can use is skipped.
  static TestPlan plan({
    required List<VocabularyWithTags> pool,
    required List<VocabularyWithTags> allWords,
    required Set<TestKind> kinds,
    required int questionCount,
    required Set<String> voiceLanguages,
    required Random random,
  }) {
    final context =
        QuestionContext(allWords: allWords, voiceLanguages: voiceLanguages);
    final selected = [
      for (final kind in TestKind.values)
        if (kinds.contains(kind)) kind,
    ];
    final counts = {for (final kind in selected) kind: 0};
    final questions = <TestQuestion>[];

    final shuffled = List<VocabularyWithTags>.of(pool)..shuffle(random);
    for (final word in shuffled) {
      if (questions.length >= questionCount) break;
      final usable = [
        for (final kind in selected)
          if (QuestionBuilder.of(kind).canBuild(word, context)) kind,
      ];
      if (usable.isEmpty) continue;

      final fewest = usable.map((k) => counts[k] ?? 0).reduce(min);
      final candidates =
          usable.where((k) => (counts[k] ?? 0) == fewest).toList();
      final kind = candidates.length == 1
          ? candidates.first
          : candidates[random.nextInt(candidates.length)];

      questions.add(QuestionBuilder.of(kind).build(word, context, random));
      counts[kind] = (counts[kind] ?? 0) + 1;
    }

    final warnings = [
      for (final kind in selected)
        if ((counts[kind] ?? 0) == 0)
          TestPlanWarning(
            kind,
            missingVoiceLanguages: kind == TestKind.listening
                ? _missingVoices(pool, voiceLanguages)
                : const [],
          ),
    ];
    return TestPlan(questions: questions, warnings: warnings);
  }

  static List<String> _missingVoices(
    List<VocabularyWithTags> pool,
    Set<String> voiceLanguages,
  ) {
    final missing = <String>{};
    for (final w in pool) {
      final language = w.word.language?.trim() ?? '';
      if (language.isNotEmpty && !voiceLanguages.contains(language)) {
        missing.add(language);
      }
    }
    return missing.toList()..sort();
  }
}
