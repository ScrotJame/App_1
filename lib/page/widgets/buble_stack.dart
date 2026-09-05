import 'package:flutter/material.dart';

class BubbleBackground extends StatelessWidget {
  const BubbleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -40, right: -30, child: _bubble(140, 0.09)),
        Positioned(top: 30, left: -20, child: _bubble(100, 0.07)),
        Positioned(bottom: 10, right: 60, child: _bubble(60, 0.06)),
      ],
    );
  }
}

Widget _bubble(double size, double opacity) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white.withValues(alpha: opacity),
  ),
);