import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../helper/streak_date_helper.dart';
import '../logic/daily_review_picker.dart';

/// The level of a word before and after one graded answer.
class LevelStep extends Equatable {
  const LevelStep(this.before, this.after);

  final int before;
  final int after;

  bool get isUp => after > before;

  bool get isChanged => after != before;

  @override
  List<Object?> get props => [before, after];
}

/// The review of one day, as stored in SharedPreferences.
class DailyReviewSession extends Equatable {
  const DailyReviewSession({
    required this.date,
    required this.target,
    required this.wordIds,
    this.adaptive = false,
    this.groupCounts = const {},
    this.answers = const {},
    this.levels = const {},
    this.completedAt,
    this.rewardClaimed = false,
  });

  static const int currentVersion = 1;

  /// `yyyy-MM-dd`, from [StreakDateHelper.keyOf].
  final String date;

  /// N, decided once when the review was created.
  final int target;

  /// Whether N came from the adaptive mode.
  final bool adaptive;

  /// Words in the order they are asked.
  final List<int> wordIds;
  final Map<DailyReviewGroup, int> groupCounts;

  /// Graded answers of the official run, by word id.
  final Map<int, bool> answers;

  /// Level before and after each graded answer, by word id.
  final Map<int, LevelStep> levels;
  final DateTime? completedAt;
  final bool rewardClaimed;

  bool get isCompleted => completedAt != null;

  int get total => wordIds.length;

  int get answeredCount => wordIds.where(answers.containsKey).length;

  int get correctCount => wordIds.where((id) => answers[id] == true).length;

  bool get allAnswered => wordIds.every(answers.containsKey);

  double get accuracy => answeredCount == 0 ? 0 : correctCount / answeredCount;

  int groupCount(DailyReviewGroup group) => groupCounts[group] ?? 0;

  DailyReviewSession withAnswer(
    int wordId, {
    required bool isCorrect,
    required LevelStep level,
  }) =>
      copyWith(
        answers: {...answers, wordId: isCorrect},
        levels: {...levels, wordId: level},
      );

  DailyReviewSession copyWith({
    List<int>? wordIds,
    Map<int, bool>? answers,
    Map<int, LevelStep>? levels,
    DateTime? completedAt,
    bool? rewardClaimed,
  }) {
    return DailyReviewSession(
      date: date,
      target: target,
      adaptive: adaptive,
      wordIds: wordIds ?? this.wordIds,
      groupCounts: groupCounts,
      answers: answers ?? this.answers,
      levels: levels ?? this.levels,
      completedAt: completedAt ?? this.completedAt,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'date': date,
        'target': target,
        'adaptive': adaptive,
        'wordIds': wordIds,
        'groupCounts': {
          for (final e in groupCounts.entries) e.key.name: e.value,
        },
        'answers': {for (final e in answers.entries) '${e.key}': e.value},
        'levels': {
          for (final e in levels.entries)
            '${e.key}': [e.value.before, e.value.after],
        },
        'completedAt': completedAt?.toIso8601String(),
        'rewardClaimed': rewardClaimed,
      };

  String encode() => jsonEncode(toJson());

  /// Null for anything that is not a valid version-1 session.
  static DailyReviewSession? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      if (json['version'] != currentVersion) return null;
      final date = json['date'];
      if (date is! String || StreakDateHelper.tryParseKey(date) == null) {
        return null;
      }
      final completedAt = json['completedAt'];
      return DailyReviewSession(
        date: date,
        target: json['target'] as int,
        adaptive: json['adaptive'] as bool? ?? false,
        wordIds: (json['wordIds'] as List).map((e) => e as int).toList(),
        groupCounts: _decodeGroups(json['groupCounts']),
        answers: _decodeAnswers(json['answers']),
        levels: _decodeLevels(json['levels']),
        completedAt: completedAt is String ? DateTime.parse(completedAt) : null,
        rewardClaimed: json['rewardClaimed'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<DailyReviewGroup, int> _decodeGroups(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final group in DailyReviewGroup.values)
        if (raw[group.name] is int) group: raw[group.name] as int,
    };
  }

  static Map<int, bool> _decodeAnswers(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries) int.parse(e.key as String): e.value as bool,
    };
  }

  static Map<int, LevelStep> _decodeLevels(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        int.parse(e.key as String): LevelStep(
          (e.value as List)[0] as int,
          (e.value as List)[1] as int,
        ),
    };
  }

  @override
  List<Object?> get props => [
        date,
        target,
        adaptive,
        wordIds,
        groupCounts,
        answers,
        levels,
        completedAt,
        rewardClaimed,
      ];
}
