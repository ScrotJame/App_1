import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/scan_review/draft/scan_card.dart';
import 'package:test_abc/page/scan_review/scan_draft_cubit.dart';
import 'package:test_abc/page/scan_vocab/scan_vocab_cubit.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/unit_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/service/pronunciation_service.dart';

import '../repository/backup_test_support.dart';

class _FakePronunciation implements PronunciationService {
  final Map<String, String> readings = {'猫': 'ねこ', '犬': 'いぬ'};

  @override
  Future<void> ensureInitialized() async {}

  @override
  bool isLanguageSupported(String? languageCode) => languageCode == 'ja';

  @override
  Future<String?> generatePronunciation(
          String text, String? languageCode) async =>
      readings[text];
}

/// Lỗi ở lần insert thứ [failOn], như đĩa đầy giữa chừng.
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

/// Chặn kiểm tra trùng cho tới khi [gate] hoàn tất.
class _GatedVocabularyRepository extends VocabularyRepository {
  _GatedVocabularyRepository(super.db, {required this.gate});

  final Future<void> gate;

  @override
  Future<bool> wordExists({
    required String word,
    required String meaning,
    int? unitId,
  }) async {
    await gate;
    return super.wordExists(word: word, meaning: meaning, unitId: unitId);
  }
}

ScannedVocabItem item(String word, String meaning, {String pron = ''}) =>
    ScannedVocabItem(
        word: word, meaning: meaning, pronunciation: pron, language: 'ja');

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

  Future<ScanDraftCubit> build(
    List<ScannedVocabItem> items, {
    int? unitId,
    VocabularyRepository? repo,
  }) async {
    final cubit = ScanDraftCubit(
      repo ?? VocabularyRepository(db),
      TagRepository(db),
      UnitRepository(db),
      _FakePronunciation(),
      defaultUnitId: unitId,
    );
    addTearDown(cubit.close);
    items.forEach(cubit.addCard);
    await cubit.load();
    return cubit;
  }

  Future<List<VocabularyEntry>> allWords() =>
      (db.select(db.vocabularyEntries)..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<void> insertCat({int? unit}) => db
      .into(db.vocabularyEntries)
      .insert(VocabularyEntriesCompanion.insert(
          word: '猫', meaning: 'cat', unitId: Value(unit)));

  test('load nạp tag, unit và sinh cách đọc cho thẻ còn thiếu', () async {
    final cubit = await build([item('猫', 'cat'), item('犬', 'dog', pron: 'x')]);

    expect(cubit.state.loadStatus, LOADSTATUS.SUCCESS);
    expect(cubit.state.units.map((u) => u.id), [unitId]);
    expect(cubit.state.tags, isNotEmpty);
    final cards = cubit.state.draft.cards;
    expect(cards.map((c) => c.pronunciation), ['ねこ', 'x']);
    expect(cards.map((c) => c.pronunciationAuto), [true, false]);
  });

  test('sửa từ thì cách đọc tự động được sinh lại', () async {
    final cubit = await build([item('猫', 'cat')]);

    await cubit.editCard(1,
        word: '犬',
        pronunciation: 'ねこ',
        basePronunciation: 'ねこ',
        meaning: 'dog',
        language: 'ja',
        tagIds: {});

    expect(cubit.state.draft.cards.single.pronunciation, 'いぬ');
  });

  test('chưa lưu thì không ghi gì vào máy', () async {
    final cubit = await build([item('猫', 'cat')]);
    await cubit.keep(1);
    expect(await allWords(), isEmpty);
    expect(cubit.state.hasUnsaved, isTrue);
  });

  test('lưu thẻ đã giữ vào đúng unit kèm tag, bỏ thẻ đã bỏ', () async {
    final cubit = await build(
        [item(' 猫 ', ' cat '), item('犬', 'dog')],
        unitId: unitId);
    await cubit.editCard(1,
        word: ' 猫 ',
        pronunciation: 'ねこ',
        basePronunciation: 'ねこ',
        meaning: ' cat ',
        language: 'ja',
        tagIds: {tagId});
    await cubit.keep(1);
    await cubit.discard(2);

    await cubit.save();

    expect(cubit.state.saveStatus, LOADSTATUS.SUCCESS);
    expect(cubit.state.savedCount, 1);
    expect(cubit.state.hasUnsaved, isFalse);
    final word = (await allWords()).single;
    expect(word.word, '猫');
    expect(word.meaning, 'cat');
    expect(word.unitId, unitId);
    expect(word.pronunciation, 'ねこ');
    expect(word.language, 'ja');
    expect(await VocabularyRepository(db).getTagIdsByWordId(word.id), [tagId]);
  });

  test('còn thẻ chưa gạt thì save không làm gì', () async {
    final cubit = await build([item('猫', 'cat'), item('犬', 'dog')]);
    await cubit.keep(1);
    await cubit.save();
    expect(await allWords(), isEmpty);
    expect(cubit.state.saveStatus, LOADSTATUS.INITAL);
  });

  test('save hai lần chỉ ghi một lần', () async {
    final cubit = await build([item('猫', 'cat')]);
    await cubit.keep(1);
    await Future.wait([cubit.save(), cubit.save()]);
    await cubit.save();
    expect(await allWords(), hasLength(1));
  });

  test('cảnh báo trùng theo unit và cập nhật khi đổi unit', () async {
    await insertCat(unit: unitId);
    final cubit = await build([item('猫', 'cat')], unitId: unitId);
    expect(cubit.state.duplicateOf(1), DuplicateKind.stored);

    await cubit.setUnit(1, null);
    expect(cubit.state.duplicateOf(1), DuplicateKind.none);
  });

  test('thẻ trùng vẫn giữ được và được lưu thêm một bản', () async {
    await insertCat();
    final cubit = await build([item('猫', 'cat')]);
    await cubit.keep(1);
    await cubit.save();
    expect(await allWords(), hasLength(2));
  });

  test('thẻ trùng một thẻ đã giữ được cảnh báo, hoàn tác thì hết', () async {
    final cubit = await build([item('猫', 'cat'), item(' 猫', 'cat ')]);
    expect(cubit.state.duplicateOf(2), DuplicateKind.none);
    await cubit.keep(1);
    expect(cubit.state.duplicateOf(2), DuplicateKind.inDraft);
    await cubit.undo();
    expect(cubit.state.duplicateOf(2), DuplicateKind.none);
  });

  test('giữ thẻ thiếu nghĩa thì báo lỗi', () async {
    final cubit = await build([item('猫', '')]);
    final messages = <String>[];
    final sub = cubit.messageController.listen(messages.add);
    addTearDown(sub.cancel);

    await cubit.keep(1);
    await pumpEventQueue();

    expect(cubit.state.draft.current?.id, 1);
    expect(messages, [S.current.scan_review_incomplete]);
  });

  test('lỗi giữa chừng: không ghi gì, giữ thẻ, báo một lần', () async {
    final cubit = await build(
      [item('猫', 'cat'), item('犬', 'dog')],
      unitId: unitId,
      repo: _FailingVocabularyRepository(db, failOn: 2),
    );
    await cubit.keep(1);
    await cubit.keep(2);
    final messages = <String>[];
    final sub = cubit.messageController.listen(messages.add);
    addTearDown(sub.cancel);

    await cubit.save();
    await pumpEventQueue();

    expect(cubit.state.saveStatus, LOADSTATUS.FAILED);
    expect(await allWords(), isEmpty);
    expect(cubit.state.draft.kept, hasLength(2));
    expect(messages, hasLength(1));
    expect(messages.single, contains('disk full'));
  });

  test('đổi thẻ khi đang tải thì màn duyệt vẫn tải xong', () async {
    final cubit = ScanDraftCubit(
      VocabularyRepository(db),
      TagRepository(db),
      UnitRepository(db),
      _FakePronunciation(),
    );
    addTearDown(cubit.close);
    cubit.addCard(item('猫', 'cat'));

    final loading = cubit.load();
    await cubit.setUnit(1, unitId);
    await loading;

    expect(cubit.state.loadStatus, LOADSTATUS.SUCCESS);
    expect(cubit.state.units.map((u) => u.id), [unitId]);
    expect(cubit.state.tags, isNotEmpty);
    expect(cubit.state.draft.cards.single.pronunciation, 'ねこ');
    expect(cubit.state.isCheckingDuplicates, isFalse);
    expect(cubit.state.canKeep, isTrue);
  });

  test('chưa kiểm tra trùng xong thì chưa được giữ thẻ', () async {
    final gate = Completer<void>();
    final cubit = ScanDraftCubit(
      _GatedVocabularyRepository(db, gate: gate.future),
      TagRepository(db),
      UnitRepository(db),
      _FakePronunciation(),
    );
    addTearDown(cubit.close);
    cubit.addCard(item('猫', 'cat'));

    final loading = cubit.load();
    await pumpEventQueue();
    expect(cubit.state.loadStatus, LOADSTATUS.SUCCESS);
    expect(cubit.state.canKeep, isFalse);

    gate.complete();
    await loading;
    expect(cubit.state.canKeep, isTrue);
  });
}
