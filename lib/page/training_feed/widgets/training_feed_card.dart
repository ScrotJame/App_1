import 'package:equatable/equatable.dart';

import '../../../models/tag_vocab.dart';

enum TrainingFeedCardType { learn, quiz, audioQuiz, reward, breakPoint }

enum TrainingFeedEventType { none, luckyWord, comboBoost, mysteryCard }

class TrainingFeedEvent extends Equatable {
  const TrainingFeedEvent({
    required this.type,
    required this.title,
    required this.multiplier,
  });

  const TrainingFeedEvent.none()
      : type = TrainingFeedEventType.none,
        title = '',
        multiplier = 1.0;

  final TrainingFeedEventType type;
  final String title;
  final double multiplier;

  bool get isActive => type != TrainingFeedEventType.none;

  @override
  List<Object?> get props => [type, title, multiplier];
}

class TrainingFeedCard extends Equatable {
  const TrainingFeedCard({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.word,
    this.choices = const [],
    this.correctChoiceIndex,
    this.selectedChoiceIndex,
    this.event = const TrainingFeedEvent.none(),
    this.xpPreview = 0,
    this.gemsPreview = 0,
    this.isRevealed = false,
    this.isCompleted = false,
  });

  final String id;
  final TrainingFeedCardType type;
  final String title;
  final String subtitle;
  final VocabularyWithTags? word;
  final List<String> choices;
  final int? correctChoiceIndex;
  final int? selectedChoiceIndex;
  final TrainingFeedEvent event;
  final int xpPreview;
  final int gemsPreview;
  final bool isRevealed;
  final bool isCompleted;

  bool get isAnswered => selectedChoiceIndex != null;

  bool get isCorrect =>
      selectedChoiceIndex != null && selectedChoiceIndex == correctChoiceIndex;

  TrainingFeedCard copyWith({
    String? id,
    TrainingFeedCardType? type,
    String? title,
    String? subtitle,
    VocabularyWithTags? word,
    List<String>? choices,
    int? correctChoiceIndex,
    Object? selectedChoiceIndex = _sentinel,
    TrainingFeedEvent? event,
    int? xpPreview,
    int? gemsPreview,
    bool? isRevealed,
    bool? isCompleted,
  }) {
    return TrainingFeedCard(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      word: word ?? this.word,
      choices: choices ?? this.choices,
      correctChoiceIndex: correctChoiceIndex ?? this.correctChoiceIndex,
      selectedChoiceIndex: selectedChoiceIndex == _sentinel
          ? this.selectedChoiceIndex
          : selectedChoiceIndex as int?,
      event: event ?? this.event,
      xpPreview: xpPreview ?? this.xpPreview,
      gemsPreview: gemsPreview ?? this.gemsPreview,
      isRevealed: isRevealed ?? this.isRevealed,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        word?.word.id,
        choices,
        correctChoiceIndex,
        selectedChoiceIndex,
        event,
        xpPreview,
        gemsPreview,
        isRevealed,
        isCompleted,
      ];
}

const _sentinel = Object();
