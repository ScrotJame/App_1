import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/test_word/logic/test_grader.dart';

void main() {
  test('a correct answer levels up a word not levelled up today', () {
    expect(TestGrader.actionFor(isCorrect: true, leveledToday: false),
        GradeAction.levelUp);
  });

  test('a correct answer on a word levelled up today is only recorded', () {
    expect(TestGrader.actionFor(isCorrect: true, leveledToday: true),
        GradeAction.recordOnly);
  });

  test('a wrong answer always lowers the level', () {
    expect(TestGrader.actionFor(isCorrect: false, leveledToday: false),
        GradeAction.levelDown);
    expect(TestGrader.actionFor(isCorrect: false, leveledToday: true),
        GradeAction.levelDown);
  });
}
