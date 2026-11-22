import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.kBlueBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.kBlue,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 16, color: AppColors.kTextMuted)),
          ],
        ],
      ),
    );
  }
}
