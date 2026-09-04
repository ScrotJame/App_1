import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/models/tag_vocab.dart';
import 'package:test_abc/page/training_feed/training_feed_engine.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';

void main() {
  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  group('TrainingFeedEngine Tests', () {
    late List<VocabularyWithTags> dummyWords;

    setUp(() {
      dummyWords = List.generate(10, (i) {
        return VocabularyWithTags(
          word: VocabularyEntry(
            id: i + 1,
            word: 'Word ${i + 1}',
            meaning: 'Meaning ${i + 1}',
            level: 0,
            correctCount: 0,
            wrongCount: 0,
            easeFactor: 2.5,
            repetitions: 0,
            interval: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      });
    });

    test('buildInitialDeck should never have breakPoint at index 0', () {
      final engine = TrainingFeedEngine();
      final deck = engine.buildInitialDeck(dummyWords);

      expect(deck.isNotEmpty, true);
      expect(deck.first.type, isNot(equals(TrainingFeedCardType.breakPoint)));
    });

    test('buildInitialDeck should never have consecutive reward/breakPoint cards', () {
      final engine = TrainingFeedEngine();
      final deck = engine.buildInitialDeck(dummyWords);

      for (int i = 0; i < deck.length - 1; i++) {
        final current = deck[i].type;
        final next = deck[i + 1].type;

        final isCurrentSpecial = current == TrainingFeedCardType.reward ||
            current == TrainingFeedCardType.breakPoint;
        final isNextSpecial = next == TrainingFeedCardType.reward ||
            next == TrainingFeedCardType.breakPoint;

        expect(isCurrentSpecial && isNextSpecial, false,
            reason: 'Consecutive special cards at indices $i and ${i + 1}: $current followed by $next');
      }
    });

    test('Generating 500 consecutive cards should never violate constraints', () {
      final engine = TrainingFeedEngine();
      final cards = <TrainingFeedCard>[];

      for (int i = 0; i < 500; i++) {
        final previousType = cards.isNotEmpty ? cards.last.type : null;
        final card = engine.nextCard(dummyWords, i, previousType: previousType);
        cards.add(card);
      }

      // Check first card
      expect(cards.first.type, isNot(equals(TrainingFeedCardType.breakPoint)));

      // Check consecutive cards
      for (int i = 0; i < cards.length - 1; i++) {
        final current = cards[i].type;
        final next = cards[i + 1].type;

        final isCurrentSpecial = current == TrainingFeedCardType.reward ||
            current == TrainingFeedCardType.breakPoint;
        final isNextSpecial = next == TrainingFeedCardType.reward ||
            next == TrainingFeedCardType.breakPoint;

        expect(isCurrentSpecial && isNextSpecial, false,
            reason: 'Consecutive special cards at index $i and ${i + 1}: $current followed by $next');
      }
    });
  });
}
