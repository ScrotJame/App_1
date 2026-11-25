import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';

/// Thẻ trên cùng của chồng: gạt phải để giữ, gạt trái để bỏ.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.child,
    this.behind,
    required this.canKeep,
    required this.onKeep,
    required this.onDiscard,
    required this.onKeepBlocked,
    required this.keepLabel,
    required this.discardLabel,
  });

  final Widget child;

  /// Thẻ kế tiếp, lộ phía sau.
  final Widget? behind;
  final bool canKeep;
  final VoidCallback onKeep;
  final VoidCallback onDiscard;

  /// Gạt phải khi [canKeep] là false.
  final VoidCallback onKeepBlocked;
  final String keepLabel;
  final String discardLabel;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck>
    with SingleTickerProviderStateMixin {
  static const double _thresholdFraction = 0.3;
  static const double _flingVelocity = 700;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_onTick);

  Animation<double>? _animation;
  double _dx = 0;
  bool _leaving = false;

  void _onTick() {
    final animation = _animation;
    if (animation != null) setState(() => _dx = animation.value);
  }

  Future<void> _animateTo(double target) async {
    _animation = Tween<double>(begin: _dx, end: target).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    await _controller.forward(from: 0);
  }

  Future<void> _onDragEnd(DragEndDetails details, double width) async {
    if (_leaving) return;
    final velocity = details.primaryVelocity ?? 0;
    final far = _dx.abs() > width * _thresholdFraction;
    final fast = velocity.abs() > _flingVelocity && velocity.sign == _dx.sign;
    if (!far && !fast) {
      await _animateTo(0);
      return;
    }
    final isKeep = _dx > 0;
    if (isKeep && !widget.canKeep) {
      widget.onKeepBlocked();
      await _animateTo(0);
      return;
    }
    _leaving = true;
    await _animateTo(isKeep ? width * 1.5 : -width * 1.5);
    if (!mounted) return;
    if (isKeep) {
      widget.onKeep();
    } else {
      widget.onDiscard();
    }
    // Trang thường thay deck (key theo thẻ). Nếu thẻ vẫn còn thì đưa về chỗ cũ.
    if (!mounted) return;
    setState(() {
      _dx = 0;
      _leaving = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final progress = width > 0 ? (_dx / width).clamp(-1.0, 1.0) : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (widget.behind case final behind?)
              IgnorePointer(
                child: Transform.scale(
                  scale: 0.94,
                  child: Opacity(opacity: 0.55, child: behind),
                ),
              ),
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_leaving) return;
                _controller.stop();
                setState(() => _dx += details.delta.dx);
              },
              onHorizontalDragEnd: (details) => _onDragEnd(details, width),
              onHorizontalDragCancel: () {
                if (!_leaving && _dx != 0) _animateTo(0);
              },
              child: Transform.translate(
                offset: Offset(_dx, 0),
                child: Transform.rotate(
                  angle: progress * 0.12,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.child,
                      if (_dx != 0) _buildStamp(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStamp() {
    final isKeep = _dx > 0;
    final color = isKeep ? AppColors.kGreen : AppColors.kRed;
    return Positioned(
      top: 16,
      left: isKeep ? 16 : null,
      right: isKeep ? null : 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 3),
          ),
          child: Text(
            isKeep ? widget.keepLabel : widget.discardLabel,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
