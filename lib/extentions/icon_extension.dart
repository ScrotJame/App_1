import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_images.dart';

extension IconStringExt on String? {
  String toIconData() {
    switch (this) {
      case 'IC_FREEZE':     return AppImages.imgFreezeStreak;
      case 'IC_GET_GEMS':       return AppImages.imgLogo;
      case 'SAVE_STREAK':   return AppImages.imgLogo;
      case 'reading':     return AppImages.imgGem;
      case 'practice':    return AppImages.imgGem;
      case 'exam':        return AppImages.imgGem;
      case 'ic_gems':     return AppImages.imgGem;
      case 'ic_heart':    return AppImages.imgGem;
      case 'ic_shield':   return AppImages.imgGem;
      case 'ic_boost':    return AppImages.imgGem;
      default:            return AppImages.imgLogo;
    }
  }
}