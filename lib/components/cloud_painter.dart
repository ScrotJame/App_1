import 'package:flutter/material.dart';

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.15, h * 0.9)
      ..arcToPoint(Offset(w * 0.12, h * 0.55),
          radius: Radius.circular(h * 0.35))
      ..arcToPoint(Offset(w * 0.30, h * 0.30),
          radius: Radius.circular(h * 0.40))
      ..arcToPoint(Offset(w * 0.52, h * 0.20),
          radius: Radius.circular(h * 0.35))
      ..arcToPoint(Offset(w * 0.75, h * 0.28),
          radius: Radius.circular(h * 0.32))
      ..arcToPoint(Offset(w * 0.90, h * 0.55),
          radius: Radius.circular(h * 0.30))
      ..arcToPoint(Offset(w * 0.88, h * 0.90),
          radius: Radius.circular(h * 0.40))
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}