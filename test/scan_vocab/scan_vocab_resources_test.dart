import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/scan_vocab/scan_vocab_cubit.dart';

import 'scan_vocab_test_support.dart';

/// Recognizer mà test tự quyết khi nào mỗi lần quét xong.
class _ControlledRecognizer implements ScanTextRecognizer {
  final List<Completer<OcrScanResult>> pending = [];

  @override
  Future<OcrScanResult> recognize(File imageFile) {
    final c = Completer<OcrScanResult>();
    pending.add(c);
    return c.future;
  }
}

/// Detector mà test tự quyết khi nào mỗi lần nhận diện xong.
class _ControlledDetector implements ScanLanguageDetector {
  final List<Completer<String?>> pending = [];
  bool closed = false;

  @override
  Future<String?> identify(String text) {
    final c = Completer<String?>();
    pending.add(c);
    return c.future;
  }

  @override
  Future<void> close() async => closed = true;
}

OcrScanResult _result(String text) => OcrScanResult(
      imageSize: const Size(200, 100),
      blocks: [block(text, 0, 0, 20, 20)],
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  const displayRect = Rect.fromLTWH(10, 20, 100, 50);

  group('chống race khi quét', () {
    test('ảnh cũ quét xong sau ảnh mới không ghi đè kết quả mới', () async {
      final recognizer = _ControlledRecognizer();
      final cubit = ScanVocabCubit(recognizer: recognizer, languageDetector: FakeLanguageDetector());

      final first = cubit.runOcr(dummyFile);
      final second = cubit.runOcr(dummyFile);
      recognizer.pending[1].complete(_result('new'));
      await second;
      recognizer.pending[0].complete(_result('old'));
      await first;

      expect(cubit.state.status, SCANSTATUS.scanned);
      expect(cubit.state.blocks.single.text, 'new');
      await cubit.close();
    });

    test('lỗi của lần quét cũ không ghi đè kết quả mới', () async {
      final recognizer = _ControlledRecognizer();
      final cubit = ScanVocabCubit(recognizer: recognizer, languageDetector: FakeLanguageDetector());

      final first = cubit.runOcr(dummyFile);
      final second = cubit.runOcr(dummyFile);
      recognizer.pending[1].complete(_result('new'));
      await second;
      recognizer.pending[0].completeError(Exception('old failed'));
      await first;

      expect(cubit.state.status, SCANSTATUS.scanned);
      expect(cubit.state.errorText, isEmpty);
      await cubit.close();
    });

    test('resetScan huỷ kết quả của lần quét đang chạy', () async {
      final recognizer = _ControlledRecognizer();
      final cubit = ScanVocabCubit(recognizer: recognizer, languageDetector: FakeLanguageDetector());

      final run = cubit.runOcr(dummyFile);
      cubit.resetScan();
      recognizer.pending[0].complete(_result('late'));
      await run;

      expect(cubit.state.status, SCANSTATUS.idle);
      expect(cubit.state.blocks, isEmpty);
      await cubit.close();
    });

    test('quét xong sau khi cubit đóng thì không emit (không ném lỗi)', () async {
      final recognizer = _ControlledRecognizer();
      final cubit = ScanVocabCubit(recognizer: recognizer, languageDetector: FakeLanguageDetector());

      final run = cubit.runOcr(dummyFile);
      await cubit.close();
      recognizer.pending[0].complete(_result('late'));
      await expectLater(run, completes);
    });
  });

  group('chống race khi nhận diện ngôn ngữ', () {
    test('kết quả cũ về sau kết quả mới thì bị bỏ', () async {
      final detector = _ControlledDetector();
      final cubit = ScanVocabCubit(
        recognizer: FakeTextRecognizer(result: OcrScanResult(
          imageSize: const Size(200, 100),
          blocks: [block('cat', 0, 0, 20, 20), block('hello', 100, 40, 140, 60)],
        )),
        languageDetector: detector,
      );
      await cubit.runOcr(dummyFile);

      cubit.tapAt(const Offset(15, 25), displayRect); // chọn cat → nhận diện #0
      cubit.tapAt(const Offset(70, 45), displayRect); // thêm hello → nhận diện #1
      expect(detector.pending, hasLength(2));

      detector.pending[1].complete('en');
      await _flush();
      detector.pending[0].complete('ja');
      await _flush();

      expect(cubit.state.detectedLanguage, 'en');
      await cubit.close();
    });

    test('nhận diện xong sau khi bỏ hết lựa chọn thì không gắn lại ngôn ngữ', () async {
      final detector = _ControlledDetector();
      final cubit = ScanVocabCubit(
        recognizer: FakeTextRecognizer(result: _result('食べ')),
        languageDetector: detector,
      );
      await cubit.runOcr(dummyFile);

      cubit.tapAt(const Offset(15, 25), displayRect);
      cubit.clearAllSelections();
      detector.pending[0].complete('ja');
      await _flush();

      expect(cubit.state.detectedLanguage, isNull);
      await cubit.close();
    });

    test('nhận diện xong sau khi cubit đóng thì không emit (không ném lỗi)', () async {
      final detector = _ControlledDetector();
      final cubit = ScanVocabCubit(
        recognizer: FakeTextRecognizer(result: _result('食べ')),
        languageDetector: detector,
      );
      await cubit.runOcr(dummyFile);
      cubit.tapAt(const Offset(15, 25), displayRect);
      await cubit.close();

      detector.pending[0].complete('ja');
      await _flush();
      expect(cubit.isClosed, isTrue);
    });

    test('close() đóng bộ nhận diện ngôn ngữ', () async {
      final detector = _ControlledDetector();
      final cubit = ScanVocabCubit(recognizer: FakeTextRecognizer(), languageDetector: detector);
      await cubit.close();
      expect(detector.closed, isTrue);
    });
  });

  group('preview nối chữ', () {
    test('từ / cách đọc / nghĩa nối liền CJK, giữ dấu cách Latin', () async {
      final cubit = ScanVocabCubit(
        recognizer: FakeTextRecognizer(result: OcrScanResult(
          imageSize: const Size(200, 100),
          blocks: [
            block('食べ', 0, 0, 10, 10),
            block('物', 10, 0, 20, 10),
            block('たべ', 0, 20, 10, 30),
            block('もの', 10, 20, 20, 30),
            block('food', 0, 40, 10, 50),
            block('item', 10, 40, 20, 50),
          ],
        )),
        languageDetector: FakeLanguageDetector(),
      );
      await cubit.runOcr(dummyFile);
      // Chọn bằng kéo: mỗi hàng một vai trò. Ảnh→widget: x/2+10, y/2+20.
      void dragRow(double top, double bottom) {
        cubit.startDrag(Offset(9, top / 2 + 20 + 1));
        cubit.updateDrag(Offset(21, bottom / 2 + 20 - 1));
        cubit.endDrag(const Size(120, 90), displayRect);
      }

      dragRow(0, 10);
      cubit.setActiveRole(TokenRole.pronunciation);
      dragRow(20, 30);
      cubit.setActiveRole(TokenRole.meaning);
      dragRow(40, 50);

      final preview = cubit.state.currentPreview;
      expect(preview.word, '食べ物');
      expect(preview.pronunciation, 'たべもの');
      expect(preview.meaning, 'food item');
      await cubit.close();
    });
  });

  group('readEncodedImageSize', () {
    test('đọc đúng rộng x cao mà không cần giải mã ảnh', () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 7, 3),
        ui.Paint()..color = const Color(0xFF000000),
      );
      final image = await recorder.endRecording().toImage(7, 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      final size = await readEncodedImageSize(png!.buffer.asUint8List());
      expect(size, const Size(7, 3));
    });
  });
}
