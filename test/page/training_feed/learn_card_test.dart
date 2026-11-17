import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/models/tag_vocab.dart';
import 'package:test_abc/page/training_feed/screen/learn_card.dart';
import 'package:test_abc/page/training_feed/training_feed_cubit.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';

class FakeTrainingFeedCubit extends Cubit<TrainingFeedState>
    implements TrainingFeedCubit {
  FakeTrainingFeedCubit() : super(const TrainingFeedState());

  bool revealCardCalled = false;
  String? revealedCardId;

  @override
  void revealCard(String cardId) {
    revealCardCalled = true;
    revealedCardId = cardId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTrainingFeedCubit fakeCubit;
  late TrainingFeedCard dummyCard;

  setUp(() {
    fakeCubit = FakeTrainingFeedCubit();
    dummyCard = TrainingFeedCard(
      id: 'test_card_1',
      type: TrainingFeedCardType.learn,
      title: 'Serendipity',
      subtitle: '',
      word: VocabularyWithTags(
        word: VocabularyEntry(
          id: 1,
          word: 'Serendipity',
          meaning: 'Sự tình cờ may mắn',
          pronunciation: '/ˌser.ənˈdɪp.ə.ti/',
          level: 0,
          correctCount: 0,
          wrongCount: 0,
          easeFactor: 2.5,
          repetitions: 0,
          interval: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      isRevealed: false,
    );
  });

  Widget createTestWidget({required TrainingFeedCard card, Locale locale = const Locale('vi')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: BlocProvider<TrainingFeedCubit>.value(
          value: fakeCubit,
          child: Center(
            child: LearnCard(card: card),
          ),
        ),
      ),
    );
  }

  testWidgets('LearnCard displays TỪ VỰNG eyebrow and hides meaning initially', (tester) async {
    await tester.pumpWidget(createTestWidget(card: dummyCard));
    await tester.pump();

    // Verify eyebrow label is "TỪ VỰNG" for vi locale
    expect(find.text('TỪ VỰNG'), findsOneWidget);

    // Verify meaning widget is present in tree (keeping fixed card dimensions) but hidden (opacity 0.0)
    final meaningOpacityFinder = find.ancestor(
      of: find.text('Sự tình cờ may mắn'),
      matching: find.byType(AnimatedOpacity),
    );
    expect(meaningOpacityFinder, findsOneWidget);
    final initialOpacity = tester.widget<AnimatedOpacity>(meaningOpacityFinder);
    expect(initialOpacity.opacity, 0.0);

    // Verify revealCard was not called yet
    expect(fakeCubit.revealCardCalled, isFalse);
  });

  testWidgets('LearnCard displays VOCABULARY eyebrow in en locale', (tester) async {
    await tester.pumpWidget(createTestWidget(card: dummyCard, locale: const Locale('en')));
    await tester.pump();

    // Verify eyebrow label is "VOCABULARY" for en locale
    expect(find.text('VOCABULARY'), findsOneWidget);
  });

  testWidgets('Tapping LearnCard reveals meaning, pronunciation and calls revealCard', (tester) async {
    await tester.pumpWidget(createTestWidget(card: dummyCard));
    await tester.pump();

    // Tap on card
    await tester.tap(find.byType(LearnCard));
    await tester.pumpAndSettle();

    // Verify revealCard was called with card id
    expect(fakeCubit.revealCardCalled, isTrue);
    expect(fakeCubit.revealedCardId, 'test_card_1');

    // Verify meaning and pronunciation are now visible
    expect(find.text('Sự tình cờ may mắn'), findsOneWidget);
    expect(find.text('/ˌser.ənˈdɪp.ə.ti/'), findsOneWidget);
  });

  testWidgets('LearnCard initialized with isRevealed true starts in revealed state', (tester) async {
    final revealedCard = dummyCard.copyWith(isRevealed: true);
    await tester.pumpWidget(createTestWidget(card: revealedCard));
    await tester.pump();

    expect(find.text('TỪ VỰNG'), findsOneWidget);
    expect(find.text('Sự tình cờ may mắn'), findsOneWidget);
    expect(find.text('/ˌser.ənˈdɪp.ə.ti/'), findsOneWidget);
  });
}
