import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:test_abc/helper/language_helper.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

import '../../commons/enums.dart';
import '../../models/model_local/support_language_local.dart';
import 'ocr_text_join.dart';
import 'package:test_abc/generated/l10n.dart';

part 'scan_vocab_state.dart';
part 'scan_ocr_engine.dart';

class ScanVocabCubit extends Cubit<ScanVocabState> {
  ScanVocabCubit({
    ScanTextRecognizer? recognizer,
    ScanLanguageDetector? languageDetector,
  })  : _recognizer = recognizer ?? const MlKitScanTextRecognizer(),
        _languageDetector = languageDetector ?? MlKitScanLanguageDetector(),
        super(const ScanVocabState());

  final ScanTextRecognizer _recognizer;
  final ScanLanguageDetector _languageDetector;

  /// Khoảng chạm cho phép quanh một mảnh chữ (pixel trên màn hình).
  static const double _tapTolerance = 8;

  /// Tăng mỗi lần quét / reset; kết quả của lần quét cũ hơn bị bỏ.
  int _scanSeq = 0;

  /// Tăng mỗi lần nhận diện ngôn ngữ hoặc đổi ngôn ngữ; kết quả cũ bị bỏ.
  int _languageSeq = 0;

  @override
  Future<void> close() async {
    _scanSeq++;
    _languageSeq++;
    await _languageDetector.close();
    return super.close();
  }

  // ─── OCR + load kích thước ảnh gốc ───────────────────────────────────────
  Future<void> runOcr(File imageFile) async {
    if (isClosed) return;
    final seq = ++_scanSeq;
    _languageSeq++;
    emit(state.copyWith(
      status: SCANSTATUS.scanning,
      blocks: [],
      clearError: true,
      clearDragRect: true,
    ));

    try {
      final result = await _recognizer.recognize(imageFile);
      if (isClosed || seq != _scanSeq) return;
      emit(state.copyWith(
        imageSize: result.imageSize,
        blocks: result.blocks,
        status: SCANSTATUS.scanned,
        clearDragRect: true,
        clearLanguage: true,
      ));
    } catch (e) {
      if (isClosed || seq != _scanSeq) return;
      emit(state.copyWith(
        status: SCANSTATUS.error,
        errorMessage: S.current.error_ocr(e.toString()),
        clearLanguage: true,
      ));
    }
  }

  // ─── Đổi role active ──────────────────────────────────────────────────────
  void setActiveRole(TokenRole role) => emit(state.copyWith(activeRole: role));

  // ─── Kéo chọn (toạ độ widget). Điểm gốc giữ riêng để kéo được mọi hướng ──
  void startDrag(Offset position) {
    emit(state.copyWith(
      dragOrigin: position,
      dragRect: Rect.fromPoints(position, position),
    ));
  }

  void updateDrag(Offset position) {
    final origin = state.dragOrigin;
    if (origin == null) return;
    emit(state.copyWith(dragRect: Rect.fromPoints(origin, position)));
  }

  void endDrag(Size widgetSize, Rect displayRect) {
    final rect = state.dragRect;
    if (rect == null) {
      cancelDrag();
      return;
    }
    commitDragSelection(rect, widgetSize, displayRect);
  }

  void cancelDrag() => emit(state.copyWith(clearDragRect: true));

  // ─── Khi thả tay: chọn các block nằm trong dragRect ──────────────────────
  void commitDragSelection(Rect dragRect, Size widgetSize, Rect displayRect) {
    final imageSize = state.imageSize;
    if (imageSize == null || displayRect.isEmpty) {
      cancelDrag();
      return;
    }

    final selInImage = Rect.fromPoints(
      _toImagePoint(dragRect.topLeft, displayRect, imageSize),
      _toImagePoint(dragRect.bottomRight, displayRect, imageSize),
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

  // ─── Chạm: tìm mảnh chữ dưới ngón tay rồi chọn / bỏ chọn ──────────────────
  void tapAt(Offset position, Rect displayRect) {
    final imageSize = state.imageSize;
    if (imageSize == null || displayRect.isEmpty) return;
    if (state.status != SCANSTATUS.scanned) return;

    final point = _toImagePoint(position, displayRect, imageSize);
    final index = _hitTestBlock(point, _tapTolerance * imageSize.width / displayRect.width);
    if (index != null) tapBlock(index);
  }

  /// Mảnh chứa điểm (ưu tiên mảnh nhỏ nhất khi chồng nhau); nếu không có,
  /// mảnh gần nhất trong khoảng [tolerance] (pixel ảnh).
  int? _hitTestBlock(Offset point, double tolerance) {
    int? best;
    double bestScore = double.infinity;
    for (var i = 0; i < state.blocks.length; i++) {
      final box = state.blocks[i].boundingBox;
      if (box.contains(point)) {
        final area = box.width * box.height;
        if (area < bestScore) {
          best = i;
          bestScore = area;
        }
      }
    }
    if (best != null) return best;

    for (var i = 0; i < state.blocks.length; i++) {
      final box = state.blocks[i].boundingBox;
      if (!box.inflate(tolerance).contains(point)) continue;
      final dx = point.dx.clamp(box.left, box.right) - point.dx;
      final dy = point.dy.clamp(box.top, box.bottom) - point.dy;
      final dist = dx * dx + dy * dy;
      if (dist < bestScore) {
        best = i;
        bestScore = dist;
      }
    }
    return best;
  }

  /// Đổi toạ độ widget → toạ độ ảnh gốc (ảnh hiển thị BoxFit.contain trong [displayRect]).
  Offset _toImagePoint(Offset p, Rect displayRect, Size imageSize) {
    return Offset(
      (p.dx - displayRect.left) * imageSize.width / displayRect.width,
      (p.dy - displayRect.top) * imageSize.height / displayRect.height,
    );
  }

  // ─── Tap đơn vào block ────────────────────────────────────────────────────
  void tapBlock(int index) {
    if (index < 0 || index >= state.blocks.length) return;
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
    // Ngôn ngữ chọn tay được giữ cho tới khi chọn "Tự động" hoặc đổi ảnh.
    emit(state.copyWith(
      vocabItems: newItems,
      blocks: cleared,
      clearLanguage: !state.isLanguageManuallySet,
    ));
    await _detectLanguageFromWordBlocks();
    return true;
  }

  void setLanguageManually(String langCode) {
    _languageSeq++;
    emit(state.copyWith(
      detectedLanguage: langCode,
      isLanguageManuallySet: true,
    ));
  }

  /// Bỏ lựa chọn tay và nhận diện lại từ các mảnh "Từ vựng" đang chọn.
  Future<void> useAutoLanguage() async {
    emit(state.copyWith(clearLanguage: true));
    await _detectLanguageFromWordBlocks();
  }

  Future<void> _detectLanguageFromWordBlocks() async {
    if (state.isLanguageManuallySet) return;

    await _autoDetectLanguage(state.textForRole(TokenRole.word));
  }

  Future<void> _autoDetectLanguage(String text) async {
    if (isClosed) return;
    final seq = ++_languageSeq;
    if (text.trim().length < 2) {
      emit(state.copyWith(clearLanguage: true));
      return;
    }
    try {
      final lang = await _languageDetector.identify(text.trim());
      // Có lần nhận diện mới hơn, người dùng đã chọn tay, hoặc cubit đã đóng.
      if (isClosed || seq != _languageSeq || state.isLanguageManuallySet) return;
      emit(state.copyWith(
        detectedLanguage: lang,
        clearLanguage: lang == null,
        isLanguageManuallySet: false,
      ));
    } catch (_) {
      if (isClosed || seq != _languageSeq || state.isLanguageManuallySet) return;
      emit(state.copyWith(clearLanguage: true));
    }
  }

  Future<void> detectLanguage(String text) => _autoDetectLanguage(text);

  void clearRole(TokenRole role) {
    final cleared = state.blocks
        .map((b) => b.role == role ? b.copyWith(isSelected: false, role: TokenRole.none) : b)
        .toList();
    emit(state.copyWith(blocks: cleared));
    _detectLanguageFromWordBlocks();
  }

  void clearAllSelections() {
    final cleared = state.blocks
        .map((b) => b.copyWith(isSelected: false, role: TokenRole.none))
        .toList();
    emit(state.copyWith(blocks: cleared));
    _detectLanguageFromWordBlocks();
  }

  // ─── Reset ────────────────────────────────────────────────────────────────
  void resetScan() {
    _scanSeq++;
    _languageSeq++;
    emit(state.copyWith(
      blocks: [],
      status: SCANSTATUS.idle,
      clearDragRect: true,
      clearError: true,
      clearLanguage: true,
    ));
  }
}
