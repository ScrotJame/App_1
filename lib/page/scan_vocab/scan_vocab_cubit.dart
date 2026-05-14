import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:test_abc/helper/language_helper.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

part 'scan_vocab_state.dart';

class ScanVocabCubit extends Cubit<ScanVocabState> {
  ScanVocabCubit() : super(const ScanVocabState());

  // ─── OCR + load kích thước ảnh gốc ───────────────────────────────────────
  Future<void> runOcr(File imageFile) async {
    emit(state.copyWith(status: SCANSTATUS.scanning, blocks: [], clearError: true));

    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final imgSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );

      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = TextRecognizer(script: TextRecognitionScript.japanese);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      final blocks = <OcrBlock>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            final text = element.text.trim();
            final bb = element.boundingBox;
            if (text.isNotEmpty) {
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
        clearLanguage: true,
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
  void commitDragSelection(Rect dragRect, Size widgetSize, Rect displayRect) {
    if (state.imageSize == null) return;

    final imgW = state.imageSize!.width;
    final imgH = state.imageSize!.height;

    final scaleX = imgW / displayRect.width;
    final scaleY = imgH / displayRect.height;

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
    _detectLanguageFromWordBlocks();
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
    _detectLanguageFromWordBlocks();
  }

  // ─── Thêm từ hiện tại vào danh sách ─────────────────────────────────────
  Future<bool> addCurrentItem() async {
    var preview = state.currentPreview;
    if (preview.word.trim().isEmpty && preview.meaning.trim().isEmpty) return false;

    if (preview.language.trim().isEmpty) {
      preview = preview.copyWith(language: state.detectedLanguage ?? '');
    }

    final newItems = List<ScannedVocabItem>.from(state.vocabItems)..add(preview);
    final cleared = state.blocks
        .map((b) => b.copyWith(isSelected: false, role: TokenRole.none))
        .toList();
    emit(state.copyWith(
      vocabItems: newItems,
      blocks: cleared,
      clearLanguage: true,
    ));
    await _detectLanguageFromWordBlocks();
    return true;
  }

  void setLanguageManually(String langCode) {
    emit(state.copyWith(
      detectedLanguage: langCode,
      isLanguageManuallySet: true,
    ));
  }

  Future<void> _detectLanguageFromWordBlocks() async {
    if (state.isLanguageManuallySet) return;

    final wordText = state.blocks
        .where((b) => b.role == TokenRole.word)
        .map((b) => b.text)
        .join(' ');

    await _autoDetectLanguage(wordText);
  }

  Future<void> _autoDetectLanguage(String text) async {
    if (text.trim().length < 2) {
      emit(state.copyWith(clearLanguage: true));
      return;
    }
    try {
      final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final lang = await identifier.identifyLanguage(text.trim());
      await identifier.close();
      emit(state.copyWith(
        detectedLanguage: lang == 'und' ? null : lang,
        isLanguageManuallySet: false,
      ));
    } catch (_) {
      emit(state.copyWith(clearLanguage: true));
    }
  }

  Future<void> detectLanguage(String text) => _autoDetectLanguage(text);

  void clearRole(TokenRole role) {
    final cleared = state.blocks
        .map((b) => b.role == role ? b.copyWith(isSelected: false, role: TokenRole.none) : b)
        .toList();
    if (role == TokenRole.word) {
      emit(state.copyWith(blocks: cleared, isLanguageManuallySet: false));
    } else {
      emit(state.copyWith(blocks: cleared));
    }
    _detectLanguageFromWordBlocks();
  }

  void clearAllSelections() {
    final cleared = state.blocks
        .map((b) => b.copyWith(isSelected: false, role: TokenRole.none))
        .toList();
    emit(state.copyWith(blocks: cleared, isLanguageManuallySet: false));
    _detectLanguageFromWordBlocks();

  }

  // ─── Reset ────────────────────────────────────────────────────────────────
  void resetScan() => emit(state.copyWith(
    blocks: [],
    status: SCANSTATUS.idle,
    clearDragRect: true,
    clearError: true,
    clearLanguage: true,
  ));
}