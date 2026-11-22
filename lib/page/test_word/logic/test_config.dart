import 'package:equatable/equatable.dart';

import '../../../commons/enums.dart';
import '../../../commons/status_comon.dart';
import '../../../models/tag_vocab.dart';

const _unset = Object();

/// The one setup shared by every kind of question.
class TestConfig extends Equatable {
  const TestConfig({
    this.kinds = const {TestKind.choice},
    this.questionCount = 10,
    this.timerMode = TimerMode.total,
    this.timeLimitSeconds = defaultTotalSeconds,
    this.enableTimer = true,
    this.wordFilter = WordFilter.all,
    this.selectedTagIds = const [],
    this.selectedLanguage,
  });

  /// Version of [toJson]. Another version is ignored by [fromJson].
  static const int jsonVersion = 1;

  static const List<int> questionCountOptions = [5, 10, 15, 20, 30];
  static const List<int> totalTimeOptions = [300, 600, 900, 1200, 1800];
  static const List<int> perQuestionTimeOptions = [10, 15, 30, 45, 60];
  static const int defaultTotalSeconds = 600;
  static const int defaultPerQuestionSeconds = 15;

  /// Never empty.
  final Set<TestKind> kinds;
  final int questionCount;
  final TimerMode timerMode;

  /// The whole test in [TimerMode.total], one question in
  /// [TimerMode.perWord] (see [perQuestionSeconds]).
  final int timeLimitSeconds;
  final bool enableTimer;
  final WordFilter wordFilter;

  /// Empty means every tag.
  final List<int> selectedTagIds;

  /// Language of the words ('ja', 'en'...). Null means every language.
  final String? selectedLanguage;

  /// Seconds for one question in [TimerMode.perWord]. Typing gets twice
  /// the time.
  int perQuestionSeconds(TestKind kind) =>
      kind == TestKind.typing ? timeLimitSeconds * 2 : timeLimitSeconds;

  /// The words this setup tests.
  List<VocabularyWithTags> filterWords(List<VocabularyWithTags> words) {
    final language = selectedLanguage;
    return words.where((w) {
      final level = w.word.level;
      final byStatus = switch (wordFilter) {
        WordFilter.all => true,
        WordFilter.learned => level >= WordStatus.masteredLevel,
        WordFilter.notLearned => level < WordStatus.masteredLevel,
      };
      if (!byStatus) return false;
      if (selectedTagIds.isNotEmpty &&
          !(w.tags ?? const []).any((t) => selectedTagIds.contains(t.id))) {
        return false;
      }
      if (language != null &&
          language.isNotEmpty &&
          w.word.language != language) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Drops the tags and the language that no word has any more.
  TestConfig sanitize({
    required Set<int> tagIds,
    required Set<String> languages,
  }) {
    final language = selectedLanguage;
    return copyWith(
      kinds: kinds.isEmpty ? const {TestKind.choice} : kinds,
      selectedTagIds: selectedTagIds.where(tagIds.contains).toList(),
      selectedLanguage:
          language != null && languages.contains(language) ? language : null,
    );
  }

  TestConfig copyWith({
    Set<TestKind>? kinds,
    int? questionCount,
    TimerMode? timerMode,
    int? timeLimitSeconds,
    bool? enableTimer,
    WordFilter? wordFilter,
    List<int>? selectedTagIds,
    Object? selectedLanguage = _unset,
  }) {
    return TestConfig(
      kinds: kinds ?? this.kinds,
      questionCount: questionCount ?? this.questionCount,
      timerMode: timerMode ?? this.timerMode,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      enableTimer: enableTimer ?? this.enableTimer,
      wordFilter: wordFilter ?? this.wordFilter,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      selectedLanguage: selectedLanguage == _unset
          ? this.selectedLanguage
          : selectedLanguage as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'version': jsonVersion,
        'kinds': [
          for (final kind in TestKind.values)
            if (kinds.contains(kind)) kind.name,
        ],
        'questionCount': questionCount,
        'timerMode': timerMode.name,
        'timeLimitSeconds': timeLimitSeconds,
        'enableTimer': enableTimer,
        'wordFilter': wordFilter.name,
        'selectedTagIds': selectedTagIds,
        'selectedLanguage': selectedLanguage,
      };

  /// Null when [json] is not a version-1 setup. A missing or broken field
  /// falls back to its default.
  static TestConfig? fromJson(Object? json) {
    if (json is! Map || json['version'] != jsonVersion) return null;
    const defaults = TestConfig();

    final kinds = <TestKind>{};
    final rawKinds = json['kinds'];
    if (rawKinds is List) {
      for (final name in rawKinds) {
        final kind = _byName(TestKind.values, name);
        if (kind != null) kinds.add(kind);
      }
    }

    final tagIds = <int>[];
    final rawTags = json['selectedTagIds'];
    if (rawTags is List) tagIds.addAll(rawTags.whereType<int>());

    int positive(Object? value, int fallback) =>
        value is int && value > 0 ? value : fallback;
    final enableTimer = json['enableTimer'];
    final language = json['selectedLanguage'];

    return TestConfig(
      kinds: kinds.isEmpty ? defaults.kinds : kinds,
      questionCount: positive(json['questionCount'], defaults.questionCount),
      timerMode:
          _byName(TimerMode.values, json['timerMode']) ?? defaults.timerMode,
      timeLimitSeconds:
          positive(json['timeLimitSeconds'], defaults.timeLimitSeconds),
      enableTimer: enableTimer is bool ? enableTimer : defaults.enableTimer,
      wordFilter:
          _byName(WordFilter.values, json['wordFilter']) ?? defaults.wordFilter,
      selectedTagIds: tagIds,
      selectedLanguage:
          language is String && language.isNotEmpty ? language : null,
    );
  }

  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        kinds,
        questionCount,
        timerMode,
        timeLimitSeconds,
        enableTimer,
        wordFilter,
        selectedTagIds,
        selectedLanguage,
      ];
}
