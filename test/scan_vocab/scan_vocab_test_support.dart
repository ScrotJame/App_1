import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:test_abc/page/scan_vocab/scan_vocab_cubit.dart';

/// Recognizer giả: trả về kết quả cấu hình sẵn hoặc ném lỗi.
class FakeTextRecognizer implements ScanTextRecognizer {
  FakeTextRecognizer({this.result, this.error});

  OcrScanResult? result;
  Object? error;
  int calls = 0;

  @override
  Future<OcrScanResult> recognize(File imageFile) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return result ?? const OcrScanResult(imageSize: Size(100, 100), blocks: []);
  }
}

/// Detector giả: trả ngôn ngữ theo hàm [answer]; đếm số lần gọi.
class FakeLanguageDetector implements ScanLanguageDetector {
  FakeLanguageDetector({String? Function(String text)? answer})
      : answer = answer ?? ((_) => 'ja');

  String? Function(String text) answer;
  final List<String> asked = [];
  bool closed = false;

  @override
  Future<String?> identify(String text) async {
    asked.add(text);
    return answer(text);
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

OcrBlock block(String text, double l, double t, double r, double b) =>
    OcrBlock(text: text, boundingBox: Rect.fromLTRB(l, t, r, b));

final File dummyFile = File('dummy.jpg');
