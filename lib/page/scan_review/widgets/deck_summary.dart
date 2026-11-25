import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../generated/l10n.dart';

/// Hiện khi đã gạt hết thẻ.
class DeckSummary extends StatelessWidget {
  const DeckSummary({
    super.key,
    required this.keptCount,
    required this.discardedCount,
    required this.isSaving,
    required this.onSave,
    required this.onExit,
    required this.onUndo,
  });

  final int keptCount;
  final int discardedCount;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onExit;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final hasKept = keptCount > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_rounded,
                size: 64, color: AppColors.vocabIndigo),
            const SizedBox(height: 16),
            Text(
              s.scan_review_summary(keptCount, discardedCount),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving ? null : (hasKept ? onSave : onExit),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vocabIndigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(hasKept
                        ? s.scan_review_save_count(keptCount)
                        : s.scan_review_exit),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: isSaving ? null : onUndo,
              icon: const Icon(Icons.undo_rounded),
              label: Text(s.scan_review_undo),
            ),
          ],
        ),
      ),
    );
  }
}
