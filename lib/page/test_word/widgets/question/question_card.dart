import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../ui_test_components.dart';

/// The big card holding what the question asks about.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.label,
    required this.text,
    this.subtitle = '',
  });

  final String label;
  final String text;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          TestScreenEyebrow(label: label),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.xoayPaper,
              height: 1.2,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.xoayCyan),
            ),
          ],
        ],
      ),
    );
  }
}

/// The muted line under a question card that says what to do.
class QuestionPrompt extends StatelessWidget {
  const QuestionPrompt(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.xoayPaperDim,
      ),
    );
  }
}
