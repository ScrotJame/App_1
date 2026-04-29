import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

part 'scan_vocab_state.dart';

class ScanVocabCubit extends Cubit<ScanVocabState> {
  ScanVocabCubit() : super(const ScanVocabState());

  // ─── OCR + load kích thước ảnh gốc ───────────────────────────────────────
  Future<void> runOcr(File imageFile) async {
    emit(state.copyWith(status: SCANSTATUS.scanning, blocks: [], clearError: true));

    try {
      // Lấy kích thước ảnh gốc để tính tỉ lệ scale
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final imgSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );

      // Chạy OCR
      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = TextRecognizer(script: TextRecognitionScript.japanese);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      // Chuyển từng element thành OcrBlock có bounding box
      final blocks = <OcrBlock>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            final text = element.text.trim();
            final bb = element.boundingBox;
            if (text.isNotEmpty && bb != null) {
              blocks.add(OcrBlock(text: text, boundingBox: bb));
            }
          }
        }
      }

      emit(state.copyWith(
        imageSize: imgSize,
        blocks: blocks,
        status: SCANSTATUS.scanned,
        clearDragRect: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: SCANSTATUS.error, errorMessage: 'OCR thất bại: $e'));
    }
  }

  // ─── Đổi role active ──────────────────────────────────────────────────────
  void setActiveRole(TokenRole role) => emit(state.copyWith(activeRole: role));

  // ─── Cập nhật drag rect (toạ độ widget) ──────────────────────────────────
  void updateDragRect(Rect rect) => emit(state.copyWith(dragRect: rect));

  // ─── Khi thả tay: chọn các block nằm trong dragRect ──────────────────────
  /// [widgetSize] = kích thước của widget hiển thị ảnh
  /// [displayRect] = vùng ảnh thực sự được render trong widget (BoxFit.contain)
  void commitDragSelection(Rect dragRect, Size widgetSize, Rect displayRect) {
    if (state.imageSize == null) return;

    final imgW = state.imageSize!.width;
    final imgH = state.imageSize!.height;

    // Scale: từ toạ độ widget → toạ độ ảnh gốc
    final scaleX = imgW / displayRect.width;
    final scaleY = imgH / displayRect.height;

    // dragRect sang toạ độ ảnh gốc
    final selInImage = Rect.fromLTRB(
      (dragRect.left - displayRect.left) * scaleX,
      (dragRect.top - displayRect.top) * scaleY,
      (dragRect.right - displayRect.left) * scaleX,
      (dragRect.bottom - displayRect.top) * scaleY,
    );

    final updated = state.blocks.map((block) {
      final overlaps = selInImage.overlaps(block.boundingBox);
      if (overlaps) {
        return block.copyWith(isSelected: true, role: state.activeRole);
      }
      return block;
    }).toList();

    emit(state.copyWith(blocks: updated, clearDragRect: true));
  }

  // ─── Tap đơn vào block ────────────────────────────────────────────────────
  void tapBlock(int index) {
    final block = state.blocks[index];
    final updated = List<OcrBlock>.from(state.blocks);
    if (block.isSelected && block.role == state.activeRole) {
      updated[index] = block.copyWith(isSelected: false, role: TokenRole.none);
    } else {
      updated[index] = block.copyWith(isSelected: true, role: state.activeRole);
    }
    emit(state.copyWith(blocks: updated));
  }

  // ─── Thêm từ hiện tại vào danh sách ─────────────────────────────────────
  bool addCurrentItem() {
    final preview = state.currentPreview;
    if (preview.word.trim().isEmpty && preview.meaning.trim().isEmpty) return false;

    final newItems = List<ScannedVocabItem>.from(state.vocabItems)..add(preview);
    // Clear selection
    final cleared = state.blocks
        .map((b) => b.copyWith(isSelected: false, role: TokenRole.none))
        .toList();

    emit(state.copyWith(vocabItems: newItems, blocks: cleared));
    return true;
  }

  // ─── Reset ────────────────────────────────────────────────────────────────
  void resetScan() => emit(state.copyWith(
    blocks: [],
    status: SCANSTATUS.idle,
    clearDragRect: true,
    clearError: true,
  ));
}