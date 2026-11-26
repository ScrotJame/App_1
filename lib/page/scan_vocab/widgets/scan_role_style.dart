import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../commons/enums.dart';
import '../../../generated/l10n.dart';

Color scanRoleColor(TokenRole role) => switch (role) {
      TokenRole.word => AppColors.vocabPurple,
      TokenRole.pronunciation => AppColors.vocabBlue,
      TokenRole.meaning => AppColors.vocabOrange,
      TokenRole.none => Colors.transparent,
    };

String scanRoleLabel(TokenRole role) => switch (role) {
      TokenRole.word => S.current.scan_role_word,
      TokenRole.pronunciation => S.current.scan_role_pronunciation,
      TokenRole.meaning => S.current.scan_role_meaning,
      TokenRole.none => '',
    };
