import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/page/test_word/data/test_daily_level_store.dart';

void main() {
  final day = DateTime(2026, 11, 22, 9);
  final laterThatDay = DateTime(2026, 11, 22, 23, 30);
  final nextDay = DateTime(2026, 11, 23, 0, 5);
  late TestDailyLevelStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = TestDailyLevelStore();
  });

  test('nothing marked yet', () async {
    expect(await store.leveledToday('u', day), isEmpty);
  });

  test('marks add up during the day', () async {
    await store.markLeveled('u', 1, day);
    await store.markLeveled('u', 2, laterThatDay);

    expect(await store.leveledToday('u', laterThatDay), {1, 2});
  });

  test('a new day starts empty and replaces the old marks', () async {
    await store.markLeveled('u', 1, day);

    expect(await store.leveledToday('u', nextDay), isEmpty);

    await store.markLeveled('u', 2, nextDay);
    expect(await store.leveledToday('u', nextDay), {2});
  });

  test('each user has their own marks', () async {
    await store.markLeveled('a', 1, day);

    expect(await store.leveledToday('b', day), isEmpty);
  });

  test('broken JSON reads as nothing marked', () async {
    SharedPreferences.setMockInitialValues(
        {TestDailyLevelStore.keyFor('u'): '{oops'});

    expect(await store.leveledToday('u', day), isEmpty);
  });
}
