import 'dart:math';

import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_audio_quizz.dart';

import '../../models/tag_vocab.dart';
import 'widgets/training_feed_card.dart';

class TrainingFeedEngine {
  TrainingFeedEngine({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _sequence = 0;
  final List<int> _recentWordIds = [];

  List<TrainingFeedCard> buildInitialDeck(List<VocabularyWithTags> words) {
    if (words.isEmpty) return const [];
    final cards = <TrainingFeedCard>[];
    for (int i = 0; i < 8; i++) {
      final previousType = cards.isNotEmpty ? cards.last.type : null;
      cards.add(nextCard(words, i, previousType: previousType));
    }
    return cards;
  }

  TrainingFeedCard nextCard(
      List<VocabularyWithTags> words,
      int currentIndex, {
        TrainingFeedCardType? previousType,
      }) {
    if (words.isEmpty) {
      return _breakCard(S.current.no_words_yet, S.current.add_words_to_start);
    }

    final bool blockSpecial = previousType == TrainingFeedCardType.reward ||
        previousType == TrainingFeedCardType.breakPoint;

    if (currentIndex > 0 && currentIndex % 7 == 0) {
      if (!blockSpecial) {
        return _rewardCard();
      }
    }

    if (currentIndex > 0 && currentIndex % 11 == 0) {
      if (!blockSpecial) {
        return _breakCard(S.current.nice_run, S.current.stop_or_swipe_more);
      }
    }

    TrainingFeedCardType type = _rollCardType(words.length);
    final event = _rollEvent();
    final selectedWord = _pickWeightedWord(words);

    _rememberWord(selectedWord.word.id);

    if (currentIndex == 0 && type == TrainingFeedCardType.breakPoint) {
      type = _random.nextDouble() < 0.5
          ? TrainingFeedCardType.learn
          : TrainingFeedCardType.quiz;
    }

    if (blockSpecial &&
        (type == TrainingFeedCardType.reward ||
            type == TrainingFeedCardType.breakPoint)) {
      type = _random.nextDouble() < 0.5
          ? TrainingFeedCardType.learn
          : TrainingFeedCardType.quiz;
    }

    return switch (type) {
      TrainingFeedCardType.learn => _learnCard(selectedWord, event),
      TrainingFeedCardType.quiz => _quizCard(selectedWord, words, event),
      TrainingFeedCardType.audioQuiz => buildAudioQuizCard(
        idSeed: 'feed_${_sequence++}',
        word: selectedWord,
        allWords: words,
        event: event,
        random: _random,
      ),
      TrainingFeedCardType.reward => _rewardCard(),
      TrainingFeedCardType.breakPoint => _breakCard(
        S.current.take_a_breath,
        S.current.leave_with_progress_saved,
      ),
    };
  }

  TrainingFeedCardType _rollCardType(int wordCount) {
    final roll = _random.nextDouble();

    if (wordCount < 4) {
      return roll < 0.72
          ? TrainingFeedCardType.learn
          : TrainingFeedCardType.reward;
    }

    if (roll < 0.36) return TrainingFeedCardType.learn;
    if (roll < 0.66) return TrainingFeedCardType.quiz;
    if (roll < 0.86) return TrainingFeedCardType.audioQuiz;
    if (roll < 0.94) return TrainingFeedCardType.reward;
    return TrainingFeedCardType.breakPoint;
  }

  TrainingFeedEvent _rollEvent() {
    final roll = _random.nextDouble();
    if (roll < 0.08) {
      return TrainingFeedEvent(
        type: TrainingFeedEventType.luckyWord,
        title: S.current.lucky_word,
        multiplier: 2.0,
      );
    }
    if (roll < 0.15) {
      return TrainingFeedEvent(
        type: TrainingFeedEventType.comboBoost,
        title: S.current.combo_boost,
        multiplier: 1.5,
      );
    }
    if (roll < 0.23) {
      return TrainingFeedEvent(
        type: TrainingFeedEventType.mysteryCard,
        title: S.current.mystery_card,
        multiplier: 1.25,
      );
    }
    return const TrainingFeedEvent.none();
  }

  VocabularyWithTags _pickWeightedWord(List<VocabularyWithTags> words) {
    final scored = words
        .map((word) => MapEntry(word, _scoreWord(word)))
        .where((entry) => entry.value > 0)
        .toList();

    final total = scored.fold<double>(0, (sum, entry) => sum + entry.value);
    var cursor = _random.nextDouble() * total;

    for (final entry in scored) {
      cursor -= entry.value;
      if (cursor <= 0) return entry.key;
    }

    return scored.last.key;
  }

  double _scoreWord(VocabularyWithTags item) {
    final word = item.word;
    var score = 1.0;

    if (word.nextReview != null && word.nextReview!.isBefore(DateTime.now())) {
      score += 4.0;
    }

    if (word.level == 0) {
      score += 2.2;
    } else if (word.level < 5) {
      score += 1.4;
    } else {
      score += 0.4;
    }

    final practiceCount = word.correctCount + word.wrongCount;
    if (practiceCount == 0) score += 1.2;
    if (word.wrongCount > word.correctCount) score += 1.1;

    if (_recentWordIds.contains(word.id)) score *= 0.25;

    return max(score, 0.1);
  }

  void _rememberWord(int id) {
    _recentWordIds.add(id);
    if (_recentWordIds.length > 8) {
      _recentWordIds.removeAt(0);
    }
  }

  TrainingFeedCard _learnCard(
      VocabularyWithTags word,
      TrainingFeedEvent event,
      ) {
    final baseXp = word.word.level == 0 ? 8 : 5;
    return TrainingFeedCard(
      id: 'feed_${_sequence++}',
      type: TrainingFeedCardType.learn,
      title: word.word.word,
      subtitle: S.current.swipe_after_reveal,
      word: word,
      event: event,
      xpPreview: (baseXp * event.multiplier).round(),
      gemsPreview: event.isActive ? 2 : 1,
    );
  }

  TrainingFeedCard _quizCard(
      VocabularyWithTags word,
      List<VocabularyWithTags> allWords,
      TrainingFeedEvent event,
      ) {
    final others = allWords.where((item) => item.word.id != word.word.id).toList()
      ..shuffle(_random);

    final choices = <String>[
      word.word.meaning,
      ...others.take(3).map((item) => item.word.meaning),
    ]..shuffle(_random);

    return TrainingFeedCard(
      id: 'feed_${_sequence++}',
      type: TrainingFeedCardType.quiz,
      title: word.word.word,
      subtitle: S.current.choose_the_meaning,
      word: word,
      choices: choices,
      correctChoiceIndex: choices.indexOf(word.word.meaning),
      event: event,
      xpPreview: (10 * event.multiplier).round(),
      gemsPreview: event.isActive ? 3 : 1,
    );
  }

  TrainingFeedCard _rewardCard() {
    final rewardRoll = _random.nextDouble();
    int xp = 0;
    int gems = 0;
    int food = 0;
    if (rewardRoll < 0.4) {
      xp = 15 + _random.nextInt(15);
    } else if (rewardRoll < 0.8) {
      gems = 5 + _random.nextInt(10);
    }
    else if (rewardRoll < 0.2) {
      food = 2 + _random.nextInt(10);
    }else {
      xp = 20 + _random.nextInt(20);
      gems = 10 + _random.nextInt(10);
      food = 15 + _random.nextInt(15);
    }

    return TrainingFeedCard(
      id: 'feed_${_sequence++}',
      type: TrainingFeedCardType.reward,
      title: S.current.bonus_drop,
      subtitle: S.current.reward_for_momentum,
      xpPreview: xp,
      gemsPreview: gems,
    );
  }

  TrainingFeedCard _breakCard(String title, String subtitle) {
    return TrainingFeedCard(
      id: 'feed_${_sequence++}',
      type: TrainingFeedCardType.breakPoint,
      title: title,
      subtitle: subtitle,
      isCompleted: true,
    );
  }
}