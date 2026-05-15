import 'package:flutter/material.dart';
import '../companion_cubit.dart';

void showLevelUpDialog(BuildContext ctx, int level) {
  showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Lên cấp!', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Companion đạt cấp $level!\nBonus XP học tập tăng lên.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.6)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tuyệt vời!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showDeleteDialog(BuildContext ctx, CompanionState state, CompanionCubit cubit) {
  final current = state.activeCompanion;
  if (state.pendingDefinitionId == null) return;

  showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Xoá vĩnh viễn?', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (current != null) ...[
                    Text('${current.definition?.iconKey ?? '❓'}  ${current.displayName}  —  Cấp ${current.level}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('${current.totalWordsLearned} từ đã học cùng companion này sẽ bị mất.', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  const Text('Hành động này không thể hoàn tác.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54, side: const BorderSide(color: Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () { Navigator.of(ctx).pop(); cubit.cancelSwitch(); },
                  child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () { Navigator.of(ctx).pop(); cubit.confirmSwitch(); },
                  child: const Text('Xoá & Đổi', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
}