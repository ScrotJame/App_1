import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/batch_add_word/batch_add_word_cubit.dart';
import 'package:test_abc/page/scan_vocab/scan_vocab_cubit.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/unit_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';

import '../repository/backup_test_support.dart';

/// Fails on the [failOn]-th insert (1-based), like a disk error halfway.
class _FailingVocabularyRepository extends VocabularyRepository {
  _FailingVocabularyRepository(super.db, {required this.failOn});

  final int failOn;
  int _inserts = 0;

  @override
  Future<int> insertWord({
    required String word,
    required String meaning,
    String? pronunciation,
    String? language,
  }) {
    _inserts++;
    if (_inserts == failOn) throw StateError('disk full');
    return super.insertWord(
      word: word,
      meaning: meaning,
      pronunciation: pronunciation,
      language: language,
    );
  }
}

ScannedVocabItem _item(String word, String meaning, {String pron = ''}) =>
    ScannedVocabItem(
      word: word,
      meaning: meaning,
      pronunciation: pron,
      language: 'ja',
    );

void main() {
  late AppDatabase db;
  late int unitId;
  late int tagId;

  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  setUp(() async {
    db = await openDbWithUser('device');
    addTearDown(db.close);
    unitId = await db
        .into(db.unitsEntries)
        .insert(UnitsEntriesCompanion.insert(title: 'Unit 1'));
    tagId = (await db.select(db.tags).get()).first.id;
  });

  BatchAddWordCubit buildCubit(
    List<ScannedVocabItem> items, {
    int? unitId,
    VocabularyRepository? repo,
  }) {
    final cubit = BatchAddWordCubit(
      repo ?? VocabularyRepository(db),
      TagRepository(db),
      UnitRepository(db),
      items,
      'ja',
      unitId: unitId,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<List<VocabularyEntry>> allWords() =>
      (db.select(db.vocabularyEntries)..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  test('words scanned inside a unit are saved into that unit with tags',
      () async {
    final cubit = buildCubit(
      [_item(' 猫 ', ' cat ', pron: 'ねこ'), _item('犬', 'dog')],
      unitId: unitId,
    );
    cubit.toggleTag(0, tagId);

    await cubit.saveAll();

    expect(cubit.state.status, LOADSTATUS.SUCCESS);
    expect(cubit.state.savedCount, 2);
    expect(cubit.state.skippedCount, 0);
    final words = await allWords();
    expect(words.map((w) => w.word), ['猫', '犬']);
    expect(words.map((w) => w.meaning), ['cat', 'dog']);
    expect(words.every((w) => w.unitId == unitId), isTrue);
    expect(words.first.pronunciation, 'ねこ');
    expect(words.first.language, 'ja');
    expect(await VocabularyRepository(db).getTagIdsByWordId(words.first.id),
        [tagId]);
  });

  test('words scanned outside a unit stay without a unit', () async {
    final cubit = buildCubit([_item('猫', 'cat')]);

    await cubit.saveAll();

    final words = await allWords();
    expect(words, hasLength(1));
    expect(words.single.unitId, isNull);
  });

  test('a word already in the same unit is skipped and counted', () async {
    await db.into(db.vocabularyEntries).insert(VocabularyEntriesCompanion.insert(
          word: '猫',
          meaning: 'cat',
          unitId: Value(unitId),
          level: const Value(3),
        ));
    final cubit =
        buildCubit([_item('猫', 'cat'), _item('犬', 'dog')], unitId: unitId);

    await cubit.saveAll();

    expect(cubit.state.status, LOADSTATUS.SUCCESS);
    expect(cubit.state.savedCount, 1);
    expect(cubit.state.skippedCount, 1);
    final words = await allWords();
    expect(words.map((w) => w.word), ['猫', '犬']);
    expect(words.first.level, 3);
  });

  test('the same word in another unit is not a duplicate', () async {
    await db.into(db.vocabularyEntries).insert(
        VocabularyEntriesCompanion.insert(word: '猫', meaning: 'cat'));
    final cubit = buildCubit([_item('猫', 'cat')], unitId: unitId);

    await cubit.saveAll();

    expect(cubit.state.savedCount, 1);
    expect(cubit.state.skippedCount, 0);
    expect((await allWords()).map((w) => w.unitId), [null, unitId]);
  });

  test('a duplicate inside the scanned list is saved once', () async {
    final cubit = buildCubit(
        [_item('猫', 'cat'), _item(' 猫', 'cat '), _item('猫', 'kitten')],
        unitId: unitId);
    cubit.toggleTag(1, tagId);

    await cubit.saveAll();

    expect(cubit.state.savedCount, 2);
    expect(cubit.state.skippedCount, 1);
    final words = await allWords();
    expect(words.map((w) => w.meaning), ['cat', 'kitten']);
    // The tag picked on the dropped copy is kept on the saved one.
    expect(await VocabularyRepository(db).getTagIdsByWordId(words.first.id),
        [tagId]);
  });

  test('saving twice does not duplicate the words', () async {
    final items = [_item('猫', 'cat'), _item('犬', 'dog')];
    await buildCubit(items, unitId: unitId).saveAll();

    final again = buildCubit(items, unitId: unitId);
    await again.saveAll();

    expect(again.state.savedCount, 0);
    expect(again.state.skippedCount, 2);
    expect(await allWords(), hasLength(2));
  });

  test('a failure halfway saves nothing and reports the error once',
      () async {
    final cubit = buildCubit(
      [_item('猫', 'cat'), _item('犬', 'dog'), _item('鳥', 'bird')],
      unitId: unitId,
      repo: _FailingVocabularyRepository(db, failOn: 2),
    );
    cubit.toggleTag(0, tagId);
    final messages = <String>[];
    final sub = cubit.messageController.listen(messages.add);
    addTearDown(sub.cancel);

    await cubit.saveAll();
    await pumpEventQueue();

    expect(cubit.state.status, LOADSTATUS.FAILED);
    expect(await allWords(), isEmpty);
    expect(await db.select(db.vocabularyTags).get(), isEmpty);
    expect(messages, hasLength(1));
    expect(messages.single, contains('disk full'));

    // Editing afterwards does not bring the old error back.
    cubit.toggleTag(1, tagId);
    cubit.updateItem(2, _item('鳥', 'birdie'));
    await pumpEventQueue();
    expect(messages, hasLength(1));
  });

  test('items missing a field are reported once and nothing is saved',
      () async {
    final cubit = buildCubit([_item('猫', 'cat'), _item('犬', '')]);
    final messages = <String>[];
    final sub = cubit.messageController.listen(messages.add);
    addTearDown(sub.cancel);

    await cubit.saveAll();
    cubit.toggleTag(0, tagId);
    await pumpEventQueue();

    expect(await allWords(), isEmpty);
    expect(messages, [S.current.batch_missing_fields(1)]);
    expect(cubit.state.status, isNot(LOADSTATUS.SUCCESS));
  });
}
