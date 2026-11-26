import 'package:flutter/material.dart';

import '../scan_vocab_cubit.dart';
import 'scan_role_style.dart';

/// Vẽ khung các mảnh chữ OCR lên ảnh.
class BlockOverlayPainter extends CustomPainter {
  const BlockOverlayPainter({
    required this.blocks,
    required this.displayRect,
    required this.imageSize,
  });

  final List<OcrBlock> blocks;
  final Rect displayRect;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = displayRect.width / imageSize.width;
    final scaleY = displayRect.height / imageSize.height;

    for (final block in blocks) {
      final rect = Rect.fromLTWH(
        displayRect.left + block.boundingBox.left * scaleX,
        displayRect.top + block.boundingBox.top * scaleY,
        block.boundingBox.width * scaleX,
        block.boundingBox.height * scaleY,
      );
      final rounded =
          RRect.fromRectAndRadius(rect, const Radius.circular(4));

      if (!block.isSelected) {
        canvas.drawRRect(
          rounded,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        continue;
      }

      final color = scanRoleColor(block.role);
      canvas.drawRRect(
          rounded, Paint()..color = color.withValues(alpha: 0.35));
      canvas.drawRRect(
        rounded,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final label = TextPainter(
        text: TextSpan(
          text: ' ${scanRoleLabel(block.role)} ',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            background: Paint()..color = color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(rect.left, rect.top - 16));
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(BlockOverlayPainter old) =>
      old.blocks != blocks || old.displayRect != displayRect;
}

/// Vẽ vùng đang kéo chọn bằng nét đứt.
class DragRectPainter extends CustomPainter {
  const DragRectPainter({required this.rect, required this.color});

  final Rect rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.2));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0, gap = 4.0;
    final delta = b - a;
    final length = delta.distance;
    if (length <= 0) return;
    final direction = delta / length;
    for (var pos = 0.0; pos < length; pos += dash + gap) {
      final end = (pos + dash).clamp(0.0, length);
      canvas.drawLine(a + direction * pos, a + direction * end, paint);
    }
  }

  @override
  bool shouldRepaint(DragRectPainter old) =>
      old.rect != rect || old.color != color;
}
