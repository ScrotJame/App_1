import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/add_word/add_word_cubit.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../../repository/backup_test_support.dart';

void main() {
  late AppDatabase db;
  late AddWordCubit cubit;
  late int wordId;

  Future<VocabularyEntry> readWord() {
    return (db.select(db.vocabularyEntries)..where((t) => t.id.equals(wordId)))
        .getSingle();
  }

  setUp(() async {
    db = await openDbWithUser('device');
    addTearDown(db.close);
    cubit = AddWordCubit(VocabularyRepository(db), TagRepository(db));
    addTearDown(cubit.close);

    wordId = await db.into(db.vocabularyEntries).insert(
          VocabularyEntriesCompanion.insert(
            word: '猫',
            meaning: 'cat',
            pronunciation: const Value('ねこ'),
            language: const Value('ja'),
            level: const Value(4),
            repetitions: const Value(3),
            interval: const Value(15),
          ),
        );
  });

  test('edit mode starts with the language stored on the word', () async {
    await cubit.initForEdit(await readWord());

    expect(cubit.state.detectedLanguage, 'ja');
  });

  test('fixing only the meaning keeps language and progress', () async {
    await cubit.initForEdit(await readWord());
    cubit.onMeaningChanged('con mèo');

    await cubit.updateWord(wordId);

    expect(cubit.state.loadstatus, LOADSTATUS.SUCCESS);
    final word = await readWord();
    expect(word.meaning, 'con mèo');
    expect(word.language, 'ja');
    expect(word.pronunciation, 'ねこ');
    expect(word.level, 4);
    expect(word.repetitions, 3);
    expect(word.interval, 15);
  });

  test('a language picked by hand while editing is saved', () async {
    await cubit.initForEdit(await readWord());
    cubit.setLanguageManually('zh');

    await cubit.updateWord(wordId);

    expect((await readWord()).language, 'zh');
  });
}
