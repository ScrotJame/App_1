import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';

/// The adaptive N, saved between reviews.
class AdaptiveTarget extends Equatable {
  const AdaptiveTarget({required this.value, required this.preset});

  final int value;

  /// The preset chosen when [value] was saved. A different preset now means
  /// the user changed it, and the adaptive N starts over.
  final int preset;

  String encode() => jsonEncode({'value': value, 'preset': preset});

  static AdaptiveTarget? tryDecode(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final value = json['value'];
      final preset = json['preset'];
      if (value is! int || preset is! int) return null;
      return AdaptiveTarget(value: value, preset: preset);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [value, preset];
}

class DailyTargetDecision extends Equatable {
  const DailyTargetDecision({required this.target, this.adaptive});

  final int target;

  /// What to save as the adaptive N. Null under
  /// [DailyTarget.adaptiveFrom] learned words: then nothing is saved.
  final AdaptiveTarget? adaptive;

  bool get isAdaptive => adaptive != null;

  @override
  List<Object?> get props => [target, adaptive];
}

/// How many words today's review has. Pure: reads no storage.
class DailyTarget {
  DailyTarget._();

  static const List<int> presets = [10, 20, 30];
  static const int defaultPreset = 20;
  static const int adaptiveFrom = 100;
  static const int minTarget = 10;
  static const int maxTarget = 50;
  static const int step = 5;
  static const double raiseFrom = 0.9;
  static const double lowerBelow = 0.6;

  /// Finished reviews the adaptive N looks at.
  static const int recentWindow = 3;

  static const double _epsilon = 1e-9;

  static int normalizePreset(int? preset) =>
      preset != null && presets.contains(preset) ? preset : defaultPreset;

  static DailyTargetDecision decide({
    required int learnedCount,
    required int preset,
    AdaptiveTarget? saved,
    List<double> recentAccuracies = const [],
  }) {
    final chosen = normalizePreset(preset);
    if (learnedCount < adaptiveFrom) return DailyTargetDecision(target: chosen);

    if (saved == null || saved.preset != chosen) {
      final start = _clamp(chosen);
      return DailyTargetDecision(
        target: start,
        adaptive: AdaptiveTarget(value: start, preset: chosen),
      );
    }

    var value = saved.value;
    if (recentAccuracies.length >= recentWindow) {
      final recent =
          recentAccuracies.sublist(recentAccuracies.length - recentWindow);
      final average = recent.reduce((a, b) => a + b) / recent.length;
      if (average >= raiseFrom - _epsilon) {
        value += step;
      } else if (average < lowerBelow - _epsilon) {
        value -= step;
      }
    }
    value = _clamp(value);
    return DailyTargetDecision(
      target: value,
      adaptive: AdaptiveTarget(value: value, preset: chosen),
    );
  }

  static int _clamp(int value) => min(maxTarget, max(minTarget, value));
}
