import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/page/scan_vocab/logic/kanji_role_assigner.dart';

OcrFragment f(String text, double l, double t, double r, double b) =>
    OcrFragment(text, Rect.fromLTRB(l, t, r, b));

void main() {
  const w = TokenRole.word;
  const p = TokenRole.pronunciation;

  test('không có kanji thì tất cả là từ', () {
    expect(assignKanjiRoles([f('ある', 0, 0, 40, 20), f('コーヒー', 60, 0, 140, 20)]),
        [w, w]);
  });

  test('danh sách rỗng', () {
    expect(assignKanjiRoles([]), isEmpty);
  });

  test('okurigana đứng liền kanji là một phần của từ', () {
    expect(assignKanjiRoles([f('食', 0, 0, 20, 20), f('べる', 22, 0, 62, 20)]),
        [w, w]);
  });

  test('tiền tố hiragana đứng liền cũng là từ', () {
    expect(assignKanjiRoles([f('お', 0, 0, 20, 20), f('茶', 22, 0, 42, 20)]),
        [w, w]);
  });

  test('furigana nhỏ phía trên là âm', () {
    expect(
        assignKanjiRoles(
            [f('たべる', 0, 0, 30, 10), f('食べる', 0, 12, 60, 32)]),
        [p, w]);
  });

  test('cột cách đọc đứng xa là âm', () {
    expect(
        assignKanjiRoles(
            [f('食べる', 0, 0, 60, 20), f('たべる', 100, 0, 160, 20)]),
        [w, p]);
  });

  test('cách đọc ở dòng dưới của chữ ngang là âm', () {
    expect(
        assignKanjiRoles(
            [f('勉強', 0, 0, 40, 20), f('べんきょう', 0, 24, 100, 44)]),
        [w, p]);
  });

  test('chữ dọc: okurigana bên dưới là từ', () {
    expect(
        assignKanjiRoles(
            [f('食', 100, 0, 120, 20), f('べる', 100, 22, 120, 62)]),
        [w, w]);
  });

  test('chữ dọc: furigana nhỏ bên phải là âm', () {
    expect(
        assignKanjiRoles(
            [f('食べる', 100, 0, 120, 60), f('たべる', 122, 0, 132, 30)]),
        [w, p]);
  });

  test('chữ dọc: hai khung vuông không xét theo cột (giới hạn đã biết)', () {
    expect(
        assignKanjiRoles(
            [f('見', 100, 0, 120, 20), f('る', 100, 22, 120, 42)]),
        [w, p]);
  });

  test('phần trong ngoặc và mảnh chỉ có ngoặc là âm', () {
    expect(
        assignKanjiRoles(
            [f('食べる', 0, 0, 60, 20), f('（たべる）', 62, 0, 142, 20)]),
        [w, p]);
    expect(
        assignKanjiRoles([
          f('食べる', 0, 0, 60, 20),
          f('（', 62, 0, 82, 20),
          f('たべる', 82, 0, 142, 20),
          f('）', 142, 0, 162, 20),
        ]),
        [w, p, p, p]);
  });
}
