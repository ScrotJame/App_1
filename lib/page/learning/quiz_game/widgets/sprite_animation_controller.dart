import 'package:flutter/scheduler.dart';

import '../../../../models/sprite_sheet_models.dart';

// ═══════════════════════════════════════════════════════════════
// SPRITE ANIMATION CONTROLLER
// Pure Dart — không phụ thuộc widget lifecycle.
// Tách state machine animation ra khỏi render widget.
//
// Cách dùng:
//   final ctrl = SpriteAnimationController(vsync: this);
//   ctrl.addListener(() => setState(() {}));
//   ctrl.play(idleData, loop: true);
//   // swap không frame gap:
//   ctrl.play(atkData, loop: false, onComplete: () => ctrl.play(idleData));
// ═══════════════════════════════════════════════════════════════

class SpriteAnimationController {
  // ── Ticker (thay AnimationController để tự quản lý timing) ──
  final TickerProvider vsync;
  Ticker? _ticker;

  // ── Animation state ──────────────────────────────────────────
  SpriteSheetData? _currentData;
  bool _loop = true;
  VoidCallback? _onComplete;

  // Thời điểm bắt đầu animation hiện tại (microseconds)
  Duration _startTime = Duration.zero;
  // Tổng duration của animation hiện tại (microseconds)
  Duration _totalDuration = Duration.zero;

  int _currentFrame = 0;
  bool _isRunning = false;

  // ── Listeners (giống ChangeNotifier) ─────────────────────────
  final List<VoidCallback> _listeners = [];

  // ── Getters ──────────────────────────────────────────────────

  int get currentFrame => _currentFrame;
  bool get isRunning => _isRunning;
  SpriteSheetData? get currentData => _currentData;

  SpriteAnimationController({required this.vsync}) {
    _ticker = vsync.createTicker(_onTick);
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Phát animation mới — zero frame gap, không recreate widget.
  /// Gọi bất kỳ lúc nào kể cả đang đang chạy anim khác.
  void play(
      SpriteSheetData data, {
        bool loop = true,
        VoidCallback? onComplete,
      }) {
    _currentData = data;
    _loop = loop;
    _onComplete = onComplete;
    _currentFrame = 0;

    final anim = data.defaultAnimation;
    final ms = ((anim?.totalDuration ?? 1.0) * 1000).toInt();
    _totalDuration = Duration(milliseconds: ms);

    // Reset thời gian gốc — ticker sẽ cung cấp elapsed kể từ lần start
    _startTime = Duration.zero;
    _isRunning = true;

    if (!(_ticker?.isTicking ?? false)) {
      _ticker?.start();
    }
    // Nếu ticker đã chạy (swap mid-animation), chỉ cần update _startTime
    // trong callback _onTick đầu tiên sau khi _startTime == zero.
  }

  void stop() {
    _isRunning = false;
    _ticker?.stop();
  }

  void resume() {
    if (!_isRunning) return;
    if (!(_ticker?.isTicking ?? false)) {
      _ticker?.start();
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _listeners.clear();
  }

  // ─────────────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (!_isRunning || _currentData == null) return;

    final anim = _currentData!.defaultAnimation;
    if (anim == null) return;

    // Lần đầu vào tick sau play() → chốt startTime
    if (_startTime == Duration.zero) {
      _startTime = elapsed;
    }

    final sinceStart = elapsed - _startTime;
    final frameCount = anim.frameCount;

    if (_totalDuration == Duration.zero) return;

    // progress ∈ [0.0, 1.0)
    double progress = sinceStart.inMicroseconds / _totalDuration.inMicroseconds;

    if (progress >= 1.0) {
      if (_loop) {
        // Wrap: giữ lại phần dư để không bỏ frame
        _startTime = elapsed - Duration(
          microseconds: sinceStart.inMicroseconds % _totalDuration.inMicroseconds,
        );
        progress = (elapsed - _startTime).inMicroseconds /
            _totalDuration.inMicroseconds;
        _onComplete?.call();
      } else {
        // Dừng tại frame cuối
        _currentFrame = frameCount - 1;
        _isRunning = false;
        _ticker?.stop();
        _notifyListeners();
        _onComplete?.call();
        return;
      }
    }

    final newFrame = (progress * frameCount).floor().clamp(0, frameCount - 1);
    if (newFrame != _currentFrame) {
      _currentFrame = newFrame;
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    for (final fn in List.of(_listeners)) {
      fn();
    }
  }
}