import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/page/test_word/data/test_config_store.dart';
import 'package:test_abc/page/test_word/logic/test_config.dart';

import 'test_word_support.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TestConfig', () {
    test('defaults to multiple choice only', () {
      expect(const TestConfig().kinds, {TestKind.choice});
    });

    test('toJson and fromJson keep every field', () {
      const config = TestConfig(
        kinds: {TestKind.typing, TestKind.listening},
        questionCount: 20,
        timerMode: TimerMode.perWord,
        timeLimitSeconds: 15,
        enableTimer: false,
        wordFilter: WordFilter.notLearned,
        selectedTagIds: [3, 7],
        selectedLanguage: 'ja',
      );

      final json = jsonDecode(jsonEncode(config.toJson()));

      expect(TestConfig.fromJson(json), config);
    });

    test('another version or something that is not a map gives null', () {
      expect(TestConfig.fromJson({'version': 2}), isNull);
      expect(TestConfig.fromJson('oops'), isNull);
      expect(TestConfig.fromJson(null), isNull);
    });

    test('unknown or broken fields fall back to the default', () {
      final config = TestConfig.fromJson({
        'version': 1,
        'kinds': ['nope'],
        'questionCount': -3,
        'timerMode': 'weird',
        'enableTimer': 'yes',
        'selectedTagIds': ['a', 2],
        'selectedLanguage': '',
      });

      expect(config, const TestConfig(selectedTagIds: [2]));
    });

    test('sanitize drops the tags and the language no word has any more', () {
      const config = TestConfig(selectedTagIds: [1, 2], selectedLanguage: 'ko');

      final clean = config.sanitize(tagIds: {2, 5}, languages: {'ja'});

      expect(clean.selectedTagIds, [2]);
      expect(clean.selectedLanguage, isNull);
    });

    test('sanitize keeps a language that still has words', () {
      const config = TestConfig(selectedLanguage: 'ja');

      expect(
        config.sanitize(tagIds: {}, languages: {'ja'}).selectedLanguage,
        'ja',
      );
    });

    test('typing gets twice the per-question time', () {
      const config = TestConfig(timeLimitSeconds: 15);

      expect(config.perQuestionSeconds(TestKind.typing), 30);
      expect(config.perQuestionSeconds(TestKind.choice), 15);
      expect(config.perQuestionSeconds(TestKind.listening), 15);
      expect(config.perQuestionSeconds(TestKind.trueFalse), 15);
    });

    test('filterWords applies the status, the tags and the language', () {
      final words = [
        entry(1, '猫', 'cat', language: 'ja', level: 5, tagIds: [1]),
        entry(2, '犬', 'dog', language: 'ja', tagIds: [2]),
        entry(3, 'apple', 'táo', language: 'en', tagIds: [1]),
      ];
      List<int> ids(TestConfig config) =>
          config.filterWords(words).map((w) => w.word.id).toList();

      expect(ids(const TestConfig()), [1, 2, 3]);
      expect(ids(const TestConfig(wordFilter: WordFilter.learned)), [1]);
      expect(ids(const TestConfig(wordFilter: WordFilter.notLearned)), [2, 3]);
      expect(ids(const TestConfig(selectedTagIds: [1])), [1, 3]);
      expect(ids(const TestConfig(selectedLanguage: 'ja')), [1, 2]);
    });
  });

  group('TestConfigStore', () {
    test('nothing saved yet gives null', () async {
      expect(await TestConfigStore().load(), isNull);
    });

    test('a saved setup is loaded back', () async {
      const config = TestConfig(kinds: {TestKind.trueFalse}, questionCount: 5);
      await TestConfigStore().save(config);

      expect(await TestConfigStore().load(), config);
    });

    test('broken JSON gives null', () async {
      SharedPreferences.setMockInitialValues(
          {TestConfigStore.configKey: '{oops'});

      expect(await TestConfigStore().load(), isNull);
    });

    test('the level-down note is marked as shown', () async {
      final store = TestConfigStore();
      expect(await store.isLevelDownExplained(), isFalse);

      await store.markLevelDownExplained();

      expect(await store.isLevelDownExplained(), isTrue);
    });
  });
}
