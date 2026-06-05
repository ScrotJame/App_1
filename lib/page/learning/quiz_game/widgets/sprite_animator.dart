import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/sprite_sheet_models.dart';
import 'sprite_animation_controller.dart';

// ═══════════════════════════════════════════════════════════════
// SPRITE ANIMATOR — Pure display widget
// Nhận SpriteAnimationController từ ngoài, chỉ render frame.
// Không tự quản lý AnimationController, không dùng ValueKey dynamic.
//
// Zero frame gap khi swap animation vì:
//   - Widget không bị destroy/recreate
//   - Controller.play() update frame ngay lập tức
//   - Image đã preload trong cache → render synchronous
// ═══════════════════════════════════════════════════════════════

class SpriteAnimator extends StatefulWidget {
  final SpriteAnimationController controller;

  /// Path đến sprite sheet image. Nên preload trước qua [preloadImage].
  final String imagePath;

  final bool flipHorizontally;
  final double scale;

  // ── Static image cache ───────────────────────────────────────
  static final Map<String, ui.Image> _imageCache = {};

  static Future<void> preloadImage(String path) async {
    if (_imageCache.containsKey(path)) return;
    try {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _imageCache[path] = frame.image;
    } catch (_) {
      // Silent fail
    }
  }

  const SpriteAnimator({
    super.key,
    required this.controller,
    required this.imagePath,
    this.flipHorizontally = false,
    this.scale = 2.0,
  });

  @override
  State<SpriteAnimator> createState() => _SpriteAnimatorState();
}

class _SpriteAnimatorState extends State<SpriteAnimator> {
  ui.Image? _image;

  // ── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onFrame);
    _resolveImage(widget.imagePath);
  }

  @override
  void didUpdateWidget(covariant SpriteAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onFrame);
      widget.controller.addListener(_onFrame);
    }

    if (oldWidget.imagePath != widget.imagePath) {
      _resolveImage(widget.imagePath);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFrame);
    super.dispose();
    // Không dispose controller ở đây — owner (BattleScene) chịu trách nhiệm.
    // Không dispose _image — nó nằm trong static cache, dùng chung.
  }

  // ── Image loading ────────────────────────────────────────────

  /// Resolve image từ cache (sync) hoặc load async.
  /// Khi image đã preload → _image được gán ngay, không có frame trống.
  void _resolveImage(String path) {
    final cached = SpriteAnimator._imageCache[path];
    if (cached != null) {
      // Synchronous — không cần setState thêm, build() sẽ dùng trực tiếp
      _image = cached;
      return;
    }
    // Chưa có trong cache → load async (trường hợp không preload)
    _loadImageAsync(path);
  }

  Future<void> _loadImageAsync(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      SpriteAnimator._imageCache[path] = frame.image;
      if (mounted && widget.imagePath == path) {
        setState(() => _image = frame.image);
      }
    } catch (_) {
      // Silent fail
    }
  }

  // ── Controller callback ──────────────────────────────────────

  void _onFrame() {
    if (mounted) setState(() {});
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.currentData;

    // Fallback size khi chưa có data (hiếm gặp nếu preload đúng)
    if (data == null) {
      return const SizedBox.shrink();
    }

    final w = data.frameWidth * widget.scale;
    final h = data.frameHeight * widget.scale;

    // Giữ placeholder đúng kích thước khi image chưa sẵn
    if (_image == null) {
      return SizedBox(width: w, height: h);
    }

    final anim = data.defaultAnimation;
    final frameIndex = (anim != null ? anim.from : 0) + widget.controller.currentFrame;
    final frame = data.frames[frameIndex.clamp(0, data.frames.length - 1)];

    return CustomPaint(
      size: Size(frame.w * widget.scale, frame.h * widget.scale),
      painter: _SpriteSheetPainter(
        image: _image!,
        frame: frame,
        scale: widget.scale,
        flipHorizontally: widget.flipHorizontally,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTER — render đúng region từ sprite sheet
// ═══════════════════════════════════════════════════════════════

class _SpriteSheetPainter extends CustomPainter {
  final ui.Image image;
  final SpriteFrame frame;
  final double scale;
  final bool flipHorizontally;

  const _SpriteSheetPainter({
    required this.image,
    required this.frame,
    required this.scale,
    required this.flipHorizontally,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(frame.x, frame.y, frame.w, frame.h);
    final dst = Rect.fromLTWH(0, 0, frame.w * scale, frame.h * scale);
    final paint = Paint()..filterQuality = FilterQuality.none;

    if (flipHorizontally) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(image, src, dst, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(image, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpriteSheetPainter old) =>
      old.frame != frame || old.flipHorizontally != flipHorizontally;
}