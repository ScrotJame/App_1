
import 'package:flutter/cupertino.dart';

class IslandItem {
  final String Function(BuildContext) label;
  final Color primaryColor;
  final Color secondaryColor;
  final String? imagePath;
  final Widget Function(BuildContext) pageBuilder;

  const IslandItem({
    required this.label,
    required this.primaryColor,
    required this.secondaryColor,
    this.imagePath,
    required this.pageBuilder,
  });
}