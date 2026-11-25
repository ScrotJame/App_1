import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/scan_review/draft/scan_card.dart';
import 'package:test_abc/page/scan_review/draft/scan_draft.dart';

ScanDraft draftOf(List<String> words, {int? unitId}) {
  var draft = ScanDraft(defaultUnitId: unitId);
  for (final w in words) {
    draft = draft.add(word: w, meaning: 'm-$w', language: 'ja');
  }
  return draft;
}

ScanDraft editWith(
  ScanDraft draft,
  int id, {
  String? word,
  String? pronunciation,
  String? language,
}) {
  final card = draft.cards.firstWhere((c) => c.id == id);
  return draft.edit(
    id,
    word: word ?? card.word,
    pronunciation: pronunciation ?? card.pronunciation,
    meaning: card.meaning,
    language: language ?? card.language,
    tagIds: card.tagIds,
  );
}

void main() {
  test('thêm thẻ: id tăng dần, nhận Unit mặc định', () {
    final draft = draftOf(['a', 'b'], unitId: 7);
    expect(draft.cards.map((c) => c.id), [1, 2]);
    expect(draft.cards.map((c) => c.unitId), [7, 7]);
    expect(draft.current?.id, 1);
    expect(draft.next?.id, 2);
    expect(draft.isReviewed, isFalse);
  });

  test('draft rỗng không phải đã duyệt xong', () {
    const draft = ScanDraft();
    expect(draft.isReviewed, isFalse);
    expect(draft.current, isNull);
    expect(draft.hasUnsavedCards, isFalse);
  });

  test('keep / discard theo thứ tự rồi duyệt xong', () {
    var draft = draftOf(['a', 'b']);
    draft = draft.keep(1);
    expect(draft.current?.id, 2);
    draft = draft.discard(2);
    expect(draft.isReviewed, isTrue);
    expect(draft.kept.map((c) => c.id), [1]);
    expect(draft.discardedCount, 1);
    expect(draft.unsavedCount, 1);
  });

  test('chỉ quyết định được thẻ hiện tại', () {
    final draft = draftOf(['a', 'b']);
    expect(draft.keep(2), draft);
    expect(draft.discard(2), draft);
  });

  test('thẻ thiếu nghĩa không giữ được nhưng bỏ được', () {
    final draft = const ScanDraft().add(word: 'a');
    expect(draft.keep(1), draft);
    expect(draft.discard(1).discardedCount, 1);
  });

  test('undo trả lại thẻ vừa quyết định, nhiều lần', () {
    var draft = draftOf(['a', 'b']).keep(1).discard(2);
    draft = draft.undo();
    expect(draft.current?.id, 2);
    draft = draft.undo();
    expect(draft.current?.id, 1);
    expect(draft.canUndo, isFalse);
    expect(draft.undo(), draft);
  });

  test('thẻ thêm sau xếp cuối, quyết định cũ giữ nguyên', () {
    var draft = draftOf(['a']).keep(1);
    draft = draft.add(word: 'b', meaning: 'x');
    expect(draft.current?.id, 2);
    expect(draft.kept.single.id, 1);
  });

  test('setUnit áp cho thẻ đó, thẻ chưa gạt phía sau và thẻ mới', () {
    var draft = draftOf(['a', 'b', 'c'], unitId: 1).keep(1);
    draft = draft.setUnit(2, 9);
    expect(draft.cards.map((c) => c.unitId), [1, 9, 9]);
    draft = draft.add(word: 'd');
    expect(draft.cards.last.unitId, 9);
    draft = draft.setUnit(3, null);
    expect(draft.cards.map((c) => c.unitId), [1, 9, null, null]);
    expect(draft.defaultUnitId, isNull);
  });

  group('cách đọc', () {
    test('applyPronunciation đánh dấu tự động', () {
      var draft = draftOf(['猫']);
      draft = draft.applyPronunciation(draft.cards.single, 'ねこ');
      final card = draft.cards.single;
      expect(card.pronunciation, 'ねこ');
      expect(card.pronunciationAuto, isTrue);
      expect(card.pronunciationChecked, isTrue);
    });

    test('không sinh được vẫn đánh dấu đã thử', () {
      var draft = draftOf(['ねこ']);
      draft = draft.applyPronunciation(draft.cards.single, null);
      expect(draft.cards.single.pronunciationChecked, isTrue);
      expect(draft.cards.single.pronunciationAuto, isFalse);
    });

    test('kết quả của từ cũ bị bỏ', () {
      final before = draftOf(['猫']);
      final requested = before.cards.single;
      final edited = editWith(before, 1, word: '犬');
      expect(edited.applyPronunciation(requested, 'ねこ'), edited);
    });

    test('sửa từ xoá cách đọc tự động để sinh lại', () {
      var draft = draftOf(['猫']);
      draft = draft.applyPronunciation(draft.cards.single, 'ねこ');
      draft = editWith(draft, 1, word: '犬');
      expect(draft.cards.single.pronunciation, '');
      expect(draft.cards.single.pronunciationAuto, isFalse);
      expect(draft.cards.single.pronunciationChecked, isFalse);
    });

    test('cách đọc người dùng nhập không bị xoá hay ghi đè', () {
      var draft = editWith(draftOf(['猫']), 1, pronunciation: 'neko');
      draft = editWith(draft, 1, word: '犬');
      final card = draft.cards.single;
      expect(card.pronunciation, 'neko');
      expect(card.pronunciationChecked, isTrue);
      expect(draft.applyPronunciation(card, 'いぬ'), draft);
    });
  });

  test('isComplete bỏ qua khoảng trắng', () {
    expect(const ScanCard(id: 1, word: ' ', meaning: 'x').isComplete, isFalse);
    expect(const ScanCard(id: 1, word: 'a', meaning: 'x').isComplete, isTrue);
  });
}
