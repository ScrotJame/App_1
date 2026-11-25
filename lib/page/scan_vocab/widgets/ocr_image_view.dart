import 'dart:io';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../commons/app_colors.dart';
import '../../../commons/enums.dart';
import '../../../generated/l10n.dart';
import '../scan_vocab_cubit.dart';
import 'ocr_overlay_painters.dart';
import 'scan_role_style.dart';

/// Ảnh đang quét với khung chữ, cử chỉ chọn và trạng thái OCR.
class OcrImageView extends StatelessWidget {
  const OcrImageView({
    super.key,
    required this.imageFile,
    required this.state,
    required this.onPick,
  });

  final File imageFile;
  final ScanVocabState state;
  final ValueChanged<ImageSource> onPick;

  /// Vùng ảnh thực sự được vẽ (BoxFit.contain).
  static Rect displayRectFor(Size widgetSize, Size imageSize) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, widgetSize);
    return Alignment.center
        .inscribe(fitted.destination, Offset.zero & widgetSize);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.vocabImageBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widgetSize =
              Size(constraints.maxWidth, constraints.maxHeight);
          final imageSize = state.imageSize;
          final displayRect = imageSize == null
              ? null
              : displayRectFor(widgetSize, imageSize);
          final cubit = context.read<ScanVocabCubit>();
          final dragRect = state.dragRect;

          return GestureDetector(
            // Gốc vùng kéo là điểm chạm xuống, không phải điểm đã vượt ngưỡng.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) {
              if (displayRect != null) {
                cubit.tapAt(d.localPosition, displayRect);
              }
            },
            onPanStart: (d) => cubit.startDrag(d.localPosition),
            onPanUpdate: (d) => cubit.updateDrag(d.localPosition),
            onPanEnd: (_) {
              if (displayRect != null) {
                cubit.endDrag(widgetSize, displayRect);
              } else {
                cubit.cancelDrag();
              }
            },
            onPanCancel: cubit.cancelDrag,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(imageFile, fit: BoxFit.contain),
                if (state.status == SCANSTATUS.scanning) _buildScanning(context),
                if (state.status == SCANSTATUS.error)
                  _buildNotice(Icons.error_outline_rounded, AppColors.kRed,
                      state.errorText),
                if (state.hasNoText)
                  _buildNotice(Icons.search_off_rounded, AppColors.kAmber,
                      S.of(context).scan_no_text_found),
                if (state.status == SCANSTATUS.scanned &&
                    displayRect != null &&
                    imageSize != null)
                  CustomPaint(
                    painter: BlockOverlayPainter(
                      blocks: state.blocks,
                      displayRect: displayRect,
                      imageSize: imageSize,
                    ),
                  ),
                if (dragRect != null)
                  CustomPaint(
                    painter: DragRectPainter(
                      rect: dragRect,
                      color: scanRoleColor(state.activeRole),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: _buildPickButton(
                    Icons.photo_library_rounded,
                    S.of(context).scan_change_image,
                    () => onPick(ImageSource.gallery),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _buildPickButton(
                    Icons.camera_alt_rounded,
                    S.of(context).scan_retake,
                    () => onPick(ImageSource.camera),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanning(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(S.of(context).scan_recognizing,
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  /// Lỗi OCR / không tìm thấy chữ, hiện cố định trên ảnh.
  Widget _buildNotice(IconData icon, Color iconColor, String message) {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickButton(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.vocabIndigo),
      label: Text(label),
      backgroundColor: Colors.white,
      onPressed: onTap,
    );
  }
}
