import 'dart:ui';

import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._();

  ///Common
  static const Color mainRealAgent = Color(0xFF005CF7);
  static const Color mainTopSky = Color(0xFF1A3A8F);

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
}

class AppCommonColors {
  final String prefix;
  final dynamic commonColors;
  const AppCommonColors({
    this.prefix = 'dx_agent',
    required this.commonColors,
  });
}