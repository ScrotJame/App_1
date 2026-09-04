import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  ///Common
  static const Color primary = Color(0xFF005CF7);
  static const Color mainTopSky = Color(0xFF1A3A8F);
  static const Color white = Color(0xFFFFFFFF);
  static const kBlue = Color(0xFF2563EB);
  static const kBlueBg = Color(0xFFEFF6FF);
  static const kBlueMid = Color(0xFFDBEAFE);
  static const kGreen = Color(0xFF16A34A);
  static const kRed = Color(0xFFDC2626);
  static const kAmber = Color(0xFFF59E0B);
  static const kSurface = Color(0xFFF5F7FF);
  static const kBorder = Color(0xFFE2E8F0);
  static const textBlack =Color(0xFF000000);

  ///Gradient
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
    colors: [
      mainTopSky,
      Color(0xFF3D6FD4),
      Color(0xFFB07CC6),
    ],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6DD85E), Color(0xFF3BA82B)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF00C7FF), Color(0xFF3B77EE)],
  );

  static const LinearGradient streakGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF8C42), Color(0xFFFF5722)],
  );

  /// Xoay Từ training feed theme
  static const Color xoaySurface = Color(0xFF181426);
  static const Color xoaySurface2 = Color(0xFF1E1730);
  static const Color xoayGold = Color(0xFFFFC94D);
  static const Color xoayGoldDeep = Color(0xFFFF9F1C);
  static const Color xoayMagenta = Color(0xFFFF3D7F);
  static const Color xoayCyan = Color(0xFF3DF2D8);
  static const Color xoayPaper = Color(0xFFF5EFE3);
  static const Color xoayPaperDim = Color(0x94F5EFE3);
  static const Color xoayLine = Color(0x1AF5EFE3);

  /// Gacha & TikTok HUD Theme
  static const Color gachaDarkBg = Color(0xFF0D0B18);
  static const Color gachaGlassBg = Color(0xB31A162B);
  static const Color gachaGlassBorder = Color(0x339F8FEF);
  static const Color gachaNeonCyan = Color(0xFF00F2FE);
  static const Color gachaGold = Color(0xFFFFD000);
  static const Color gachaGoldAccent = Color(0xFFFF9500);
  static const Color gachaFlameRed = Color(0xFFFF4500);
  static const Color gachaFlameOrange = Color(0xFFFF8C00);
  static const Color gachaMagenta = Color(0xFFFF2A85);
}

class AppCommonColors {
  final String prefix;
  final dynamic commonColors;
  const AppCommonColors({
    this.prefix = 'dx_agent',
    required this.commonColors,
  });
}