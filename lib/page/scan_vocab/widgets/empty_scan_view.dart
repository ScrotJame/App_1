import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../commons/app_colors.dart';
import '../../../generated/l10n.dart';

/// Màn khi chưa có ảnh: gợi ý cách chụp và hai nút lấy ảnh.
class EmptyScanView extends StatelessWidget {
  const EmptyScanView({super.key, required this.onPick});

  final ValueChanged<ImageSource> onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.vocabPurple, AppColors.vocabBlue],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.document_scanner_rounded,
                      size: 56, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(s.scan_empty_hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(s.scan_capture_tips,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildButton(Icons.camera_alt_rounded, s.scan_take_photo,
                    () => onPick(ImageSource.camera)),
                const SizedBox(width: 12),
                _buildButton(Icons.photo_library_rounded, s.scan_gallery,
                    () => onPick(ImageSource.gallery)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.vocabIndigo,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
