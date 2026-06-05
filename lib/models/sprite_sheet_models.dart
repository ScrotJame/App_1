import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// SPRITE FRAME — một frame trong sprite sheet
// ═══════════════════════════════════════════════════════════════

class SpriteFrame extends Equatable {
  final double x;
  final double y;
  final double w;
  final double h;
  final double duration;

  const SpriteFrame({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.duration,
  });

  factory SpriteFrame.fromJson(Map<String, dynamic> json) {
    final frame = json['frame'] as Map<String, dynamic>;
    return SpriteFrame(
      x: (frame['x'] as num?)?.toDouble() ?? 0,
      y: (frame['y'] as num?)?.toDouble() ?? 0,
      w: (frame['w'] as num?)?.toDouble() ?? 0,
      h: (frame['h'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.033,
    );
  }

  @override
  List<Object?> get props => [x, y, w, h, duration];
}

// ═══════════════════════════════════════════════════════════════
// SPRITE ANIMATION — metadata cho 1 animation clip
// ═══════════════════════════════════════════════════════════════

class SpriteAnimation extends Equatable {
  final String name;
  final int from;
  final int to;
  final double fps;
  final double speedScale;

  const SpriteAnimation({
    required this.name,
    required this.from,
    required this.to,
    required this.fps,
    this.speedScale = 1.0,
  });

  factory SpriteAnimation.fromJson(Map<String, dynamic> json) {
    return SpriteAnimation(
      name: json['name'] as String? ?? 'Animation',
      from: json['from'] as int? ?? 0,
      to: json['to'] as int? ?? 0,
      fps: (json['fps'] as num?)?.toDouble() ?? 30.0,
      speedScale: (json['speed_scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  int get frameCount => to - from + 1;

  /// Tổng thời gian animation (giây)
  double get totalDuration => frameCount / (fps * speedScale);

  @override
  List<Object?> get props => [name, from, to, fps, speedScale];
}

// ═══════════════════════════════════════════════════════════════
// SPRITE SHEET DATA — root model parse từ PixelOver JSON
// ═══════════════════════════════════════════════════════════════

class SpriteSheetData extends Equatable {
  final List<SpriteFrame> frames;
  final List<SpriteAnimation> animations;
  final double sheetWidth;
  final double sheetHeight;

  const SpriteSheetData({
    required this.frames,
    required this.animations,
    required this.sheetWidth,
    required this.sheetHeight,
  });

  factory SpriteSheetData.fromJson(Map<String, dynamic> json) {
    final framesList = (json['frames'] as List<dynamic>?)
            ?.map((e) => SpriteFrame.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final size = meta['size'] as Map<String, dynamic>? ?? {};

    final animList = (meta['frameAnimations'] as List<dynamic>?)
            ?.map((e) => SpriteAnimation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SpriteSheetData(
      frames: framesList,
      animations: animList,
      sheetWidth: (size['w'] as num?)?.toDouble() ?? 0,
      sheetHeight: (size['h'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Lấy animation mặc định (đầu tiên)
  SpriteAnimation? get defaultAnimation =>
      animations.isNotEmpty ? animations.first : null;

  /// Frame width/height (lấy từ frame đầu tiên)
  double get frameWidth => frames.isNotEmpty ? frames.first.w : 0;
  double get frameHeight => frames.isNotEmpty ? frames.first.h : 0;

  /// Load từ asset path
  static Future<SpriteSheetData> loadFromAsset(String jsonPath) async {
    final jsonStr = await rootBundle.loadString(jsonPath);
    final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
    return SpriteSheetData.fromJson(jsonMap);
  }

  @override
  List<Object?> get props => [frames, animations, sheetWidth, sheetHeight];
}
