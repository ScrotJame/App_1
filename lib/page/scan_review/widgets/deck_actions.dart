import 'package:flutter/material.dart';

import '../../../commons/app_colors.dart';
import '../../../generated/l10n.dart';

/// Bốn nút dưới chồng thẻ, làm cùng việc với cử chỉ gạt.
class DeckActions extends StatelessWidget {
  const DeckActions({
    super.key,
    required this.onDiscard,
    required this.onUndo,
    required this.onEdit,
    required this.onKeep,
  });

  final VoidCallback onDiscard;

  /// null khi chưa có gì để hoàn tác.
  final VoidCallback? onUndo;
  final VoidCallback onEdit;

  /// null khi đang bận.
  final VoidCallback? onKeep;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAction(Icons.close_rounded, s.scan_review_discard,
              AppColors.kRed, onDiscard),
          _buildAction(Icons.undo_rounded, s.scan_review_undo,
              AppColors.kTextMuted, onUndo),
          _buildAction(Icons.edit_rounded, s.scan_review_edit,
              AppColors.vocabIndigo, onEdit),
          _buildAction(Icons.check_rounded, s.scan_review_keep,
              AppColors.kGreen, onKeep),
        ],
      ),
    );
  }

  Widget _buildAction(
      IconData icon, String label, Color color, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
