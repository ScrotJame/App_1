import 'dart:ui';

import 'package:flutter/cupertino.dart';

class IslandItem {
  final String label;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final Widget Function(BuildContext) pageBuilder;

  const IslandItem({
    required this.label,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pageBuilder,
  });
}