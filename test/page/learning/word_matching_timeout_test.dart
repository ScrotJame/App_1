import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/tag_vocab.dart';
import 'package:test_abc/page/learning/word_matching/word_matching_cubit.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

class _MockVocabularyRepository extends Mock implements VocabularyRepository {}

class _MockCompanionRepository extends Mock implements CompanionRepository {}

class _MockHistoryRepository extends Mock
    implements LearningHistoryRepository {}

/// The round timer and the short pauses of the game run side by side. A pause
/// that ends late must not undo what the timer decided.
void main() {
  late _MockVocabularyRepository vocabulary;
  late _MockHistoryRepository history;

  List<VocabularyWithTags> words(int count) => List.generate(count, (i) {
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
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
      });

  setUp(() {
    vocabulary = _MockVocabularyRepository();
    history = _MockHistoryRepository();
    when(() => vocabulary.watchAllWordsWithTags())
        .thenAnswer((_) => Stream.value(words(4)));
    when(() => history.recordAnswer(
          userKey: any(named: 'userKey'),
          wordId: any(named: 'wordId'),
          wordLevelSnapshot: any(named: 'wordLevelSnapshot'),
          sessionType: any(named: 'sessionType'),
          isCorrect: any(named: 'isCorrect'),
        )).thenAnswer((_) async {});
  });

  Future<WordMatchingCubit> startGame(WidgetTester tester) async {
    final cubit =
        WordMatchingCubit(vocabulary, _MockCompanionRepository(), history);
    // Not awaited: a widget test runs on fake time, pump() moves it along.
    cubit.start();
    await tester.pump();
    expect(cubit.state.gameStatus, WordMatchingGameStatus.playing);
    return cubit;
  }

  testWidgets('time running out during the "wrong pair" pause ends the game',
      (tester) async {
    final cubit = await startGame(tester);
    final roundSeconds = cubit.state.totalTime;

    // 300 ms before the last tick of the round.
    await tester.pump(
        Duration(seconds: roundSeconds) - const Duration(milliseconds: 300));
    cubit.selectLeftItem(1);
    cubit.selectRightItem(2);
    expect(cubit.state.gameStatus, WordMatchingGameStatus.wrongAnimation);

    // The timer runs out while the pause is still going.
    await tester.pump(const Duration(milliseconds: 350));
    expect(cubit.state.gameStatus, WordMatchingGameStatus.gameOver);

    // The pause ends afterwards and must leave the game over.
    await tester.pump(const Duration(seconds: 2));
    expect(cubit.state.gameStatus, WordMatchingGameStatus.gameOver);
    expect(cubit.state.timeRemaining, 0);
    expect(cubit.state.selectedLeftId, isNull);
    expect(cubit.state.selectedRightId, isNull);

    await cubit.close();
  });

  testWidgets('a wrong pair with time left goes back to playing',
      (tester) async {
    final cubit = await startGame(tester);

    cubit.selectLeftItem(1);
    cubit.selectRightItem(2);
    expect(cubit.state.gameStatus, WordMatchingGameStatus.wrongAnimation);

    await tester.pump(const Duration(milliseconds: 600));
    expect(cubit.state.gameStatus, WordMatchingGameStatus.playing);

    await cubit.close();
  });

  testWidgets('closing the game during the pause after a round is safe',
      (tester) async {
    final cubit = await startGame(tester);

    for (var id = 1; id <= 4; id++) {
      cubit.selectLeftItem(id);
      cubit.selectRightItem(id);
    }
    await tester.pump();
    expect(cubit.state.gameStatus, WordMatchingGameStatus.roundComplete);

    await cubit.close();
    // The pause ends on a closed cubit; it must not try to start a round.
    await tester.pump(const Duration(seconds: 2));

    expect(cubit.isClosed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restarting during the pause after a round keeps the new game',
      (tester) async {
    final cubit = await startGame(tester);

    for (var id = 1; id <= 4; id++) {
      cubit.selectLeftItem(id);
      cubit.selectRightItem(id);
    }
    await tester.pump();
    expect(cubit.state.gameStatus, WordMatchingGameStatus.roundComplete);

    cubit.restart();
    await tester.pump();
    expect(cubit.state.level, 1);

    // The pause of the old round ends; it must not jump to level 2.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(cubit.state.level, 1);
    expect(cubit.state.gameStatus, WordMatchingGameStatus.playing);

    await cubit.close();
  });
}
