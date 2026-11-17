import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/list_word/list_word_cubit.dart';
import 'package:test_abc/repository/unit_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/service/tts_service.dart';

import '../../repository/backup_test_support.dart';

/// The language filter narrows the list on screen. In a unit it must never
/// show a word that is not in that unit.
void main() {
  late AppDatabase db;
  late VocabularyRepository vocabulary;
  late UnitRepository units;
  late int unitId;

  List<String> shown(ListWordCubit cubit) =>
      cubit.state.filteredWords.map((w) => w.word.word).toList()..sort();

  Future<void> waitForWords(ListWordCubit cubit, int count) async {
    for (var i = 0; i < 200; i++) {
      if (cubit.state.allWords.length == count) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('Expected $count words, found ${cubit.state.allWords.length}.');
  }

  setUp(() async {
    db = await openDbWithUser('device');
    addTearDown(db.close);
    vocabulary = VocabularyRepository(db);
    units = UnitRepository(db);

    unitId = await units.insertUnit('Animals');
    final inUnit = [
      await vocabulary.insertWord(word: '猫', meaning: 'cat', language: 'ja'),
      await vocabulary.insertWord(word: '犬', meaning: 'dog', language: 'ja'),
      await vocabulary.insertWord(word: 'horse', meaning: 'ngựa', language: 'en'),
    ];
    for (final id in inUnit) {
      await units.addWordToUnit(wordId: id, unitId: unitId);
    }
    // Same languages, but outside the unit.
    await vocabulary.insertWord(word: '山', meaning: 'mountain', language: 'ja');
    await vocabulary.insertWord(word: 'river', meaning: 'sông', language: 'en');
  });

  group('in a unit', () {
    late ListWordCubit cubit;

    setUp(() async {
      cubit = ListWordCubit.forUnit(vocabulary, TtsService(), units, unitId);
      addTearDown(cubit.close);
      cubit.watchUnit();
      await waitForWords(cubit, 3);
    });

    test('a language shows only the words of the unit', () {
      cubit.onLanguageChanged('ja');

      expect(cubit.state.activeLanguage, 'ja');
      expect(shown(cubit), ['犬', '猫']);
    });

    test('clearing the language shows the whole unit again', () {
      cubit.onLanguageChanged('en');
      expect(shown(cubit), ['horse']);

      cubit.onLanguageChanged(null);

      expect(cubit.state.activeLanguage, isNull);
      expect(shown(cubit), ['horse', '犬', '猫']);
    });

    test('the language and the search box work together', () {
      cubit.onSearchChanged('dog');
      cubit.onLanguageChanged('ja');

      expect(shown(cubit), ['犬']);
    });
  });

  group('in the full list', () {
    late ListWordCubit cubit;

    setUp(() async {
      cubit = ListWordCubit(vocabulary, TtsService());
      addTearDown(cubit.close);
      await cubit.loadWords();
    });

    test('a language shows every word of that language', () {
      cubit.onLanguageChanged('ja');

      expect(shown(cubit), ['山', '犬', '猫']);
    });

    test('a language nobody uses shows an empty list', () {
      cubit.onLanguageChanged('ko');

      expect(shown(cubit), isEmpty);
    });
  });
}
