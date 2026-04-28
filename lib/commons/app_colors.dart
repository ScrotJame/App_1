import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  ///Common
  static const Color mainRealAgent = Color(0xFF005CF7);
  static const Color mainTopSky = Color(0xFF1A3A8F);
  static const Color white = Color(0xFFFFFFFF);

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
}

class AppCommonColors {
  final String prefix;
  final dynamic commonColors;
  const AppCommonColors({
    this.prefix = 'dx_agent',
    required this.commonColors,
  });
}