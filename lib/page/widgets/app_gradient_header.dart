import 'package:flutter/material.dart';

class AppGradientHeader extends StatelessWidget {
  final double height;
  final List<Color> gradientColors;
  final Widget? child;
  final List<_BubbleConfig> bubbles;

  const AppGradientHeader({
    super.key,
    required this.height,
    this.gradientColors = const [Color(0xFF42C8F5), Color(0xFF1E9FD8)],
    this.child,
    this.bubbles = const [
      _BubbleConfig(top: -40, right: -30, size: 140, opacity: 0.09),
      _BubbleConfig(top: 30, left: -20, size: 100, opacity: 0.07),
      _BubbleConfig(bottom: 10, right: 60, size: 60, opacity: 0.06),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(50),
          bottomLeft: Radius.circular(50),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bubbles
          ...bubbles.map((b) => Positioned(
            top: b.top,
            bottom: b.bottom,
            left: b.left,
            right: b.right,
            child: _buildBubble(b.size, b.opacity),
          )),
          // Custom content
          if (child != null) child!,
        ],
      ),
    );
  }

  Widget _buildBubble(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _BubbleConfig {
  final double? top, bottom, left, right;
  final double size, opacity;

  const _BubbleConfig({
    this.top, this.bottom, this.left, this.right,
    required this.size,
    required this.opacity,
  });
}