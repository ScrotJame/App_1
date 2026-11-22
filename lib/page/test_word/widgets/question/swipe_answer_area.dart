import 'package:flutter/material.dart';

/// Experiment: swipe right for "true", left for "false". Set to false (or
/// delete this file and its one use) if it does not feel right on a device.
const bool kTrueFalseSwipeEnabled = true;

class SwipeAnswerArea extends StatefulWidget {
  const SwipeAnswerArea({
    super.key,
    required this.child,
    required this.onSwipe,
    this.enabled = true,
  });

  final Widget child;

  /// True for a swipe to the right.
  final ValueChanged<bool> onSwipe;
  final bool enabled;

  @override
  State<SwipeAnswerArea> createState() => _SwipeAnswerAreaState();
}

class _SwipeAnswerAreaState extends State<SwipeAnswerArea> {
  static const _threshold = 100.0;
  double _dx = 0;

  void _reset() => setState(() => _dx = 0);

  @override
  Widget build(BuildContext context) {
    if (!kTrueFalseSwipeEnabled || !widget.enabled) return widget.child;
    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _dx += d.delta.dx),
      onHorizontalDragEnd: (_) {
        final dx = _dx;
        _reset();
        if (dx.abs() >= _threshold) widget.onSwipe(dx > 0);
      },
      onHorizontalDragCancel: _reset,
      child: Transform.translate(
        offset: Offset(_dx, 0),
        child: Transform.rotate(angle: _dx / 1200, child: widget.child),
      ),
    );
  }
}
