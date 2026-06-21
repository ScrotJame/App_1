// Pure logic for the Training Feed screen — no widget/build code here.
//
// Anything in this file should be testable without `pumpWidget`. The only
// reason `dart:ui`'s `Color` shows up is because confetti carries a palette;
// nothing here reads `BuildContext`, `State`, or does any layout. Business
// logic that touches the repository/XP system lives in `TrainingFeedCubit`
// and `TrainingFeedEngine` — this file is only the leftover bits of math
// and animation-timing logic that used to live inside widget State classes.

import 'dart:async';
import 'dart:math';
import 'dart:ui' show Color;

// ─────────────────────────────────────────────────────────────────────────
// XP / LEVEL
// ─────────────────────────────────────────────────────────────────────────

/// Derives level + progress-bar percentage from a raw XP total.
///
/// Was previously computed inline inside `_TopBar.build`.
class LevelProgress {
  const LevelProgress({required this.level, required this.xpPercent});

  final int level;
  final double xpPercent;

  factory LevelProgress.fromXp(int xpEarned) {
    final xpPercent = xpEarned > 0 ? (xpEarned % 100) / 100 : 0.0;
    final level = (xpEarned ~/ 100) + 1;
    return LevelProgress(level: level, xpPercent: xpPercent);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SLOT-MACHINE LETTER REVEAL
// ─────────────────────────────────────────────────────────────────────────

/// Drives the "slot reel" letter-lock animation used by the Learn card.
///
/// Framework-agnostic: it owns the [Timer] and the mutable letter/lock
/// arrays, and notifies the caller via plain callbacks. The widget layer
/// only needs to call [start], read [displayLetters]/[locked] in build,
/// and call [dispose] when done.
class SlotReelEngine {
  SlotReelEngine({
    required this.word,
    required this.onTick,
    required this.onLetterLocked,
    required this.onComplete,
    Random? random,
  }) : _random = random ?? Random() {
    displayLetters = List.generate(word.length, (_) => _randomLetter());
    locked = List.filled(word.length, false);
  }

  static const _tickInterval = Duration(milliseconds: 38);
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  final String word;

  /// Called after every tick so the UI can `setState`/rebuild.
  final void Function() onTick;

  /// Called the instant a given letter index locks in (good spot for
  /// haptics — kept out of this file since that's a platform/UI concern).
  final void Function(int index) onLetterLocked;

  /// Called once every letter has locked.
  final void Function() onComplete;

  final Random _random;

  late List<String> displayLetters;
  late List<bool> locked;

  Timer? _timer;
  int _tick = 0;

  String _randomLetter() => _chars[_random.nextInt(_chars.length)];

  void start() {
    _timer = Timer.periodic(_tickInterval, (timer) {
      _tick++;
      for (var i = 0; i < word.length; i++) {
        if (locked[i]) continue;
        final lockAt = (420 + i * 90) ~/ _tickInterval.inMilliseconds;
        if (_tick >= lockAt) {
          locked[i] = true;
          displayLetters[i] = word[i];
          onLetterLocked(i);
        } else {
          displayLetters[i] = _randomLetter();
        }
      }

      onTick();

      if (locked.every((b) => b)) {
        timer.cancel();
        onComplete();
      }
    });
  }

  void dispose() => _timer?.cancel();
}

// ─────────────────────────────────────────────────────────────────────────
// CONFETTI
// ─────────────────────────────────────────────────────────────────────────

/// One confetti particle's static (non-animated) properties.
///
/// The actual fall/fade animation stays in the widget layer (it's an
/// `AnimationController`/`Tween` concern); this is just the random data
/// that seeds each particle.
class ConfettoModel {
  const ConfettoModel({
    required this.id,
    required this.color,
    required this.left,
    required this.size,
    required this.duration,
    required this.rotation,
  });

  final int id;
  final Color color;
  final double left;
  final double size;
  final Duration duration;
  final double rotation;
}

/// Generates a batch of confetti particles with random palette/size/timing.
///
/// Extracted from `_ConfettiOverlayState.burst` so the randomness logic can
/// be unit-tested (e.g. by passing a seeded [random]) independently of the
/// `AnimatedBuilder` tree that renders it.
List<ConfettoModel> generateConfetti({
  required int count,
  required List<Color> palette,
  required int idStart,
  Random? random,
}) {
  final rand = random ?? Random();
  return List.generate(count, (i) {
    return ConfettoModel(
      id: idStart + i,
      color: palette[rand.nextInt(palette.length)],
      left: rand.nextDouble(),
      size: 6 + rand.nextDouble() * 6,
      duration: Duration(milliseconds: 1100 + rand.nextInt(900)),
      rotation: rand.nextDouble() * 360,
    );
  });
}