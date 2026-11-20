part of 'scan_vocab_cubit.dart';

// ─── Kết quả một lần quét: kích thước ảnh gốc + các mảnh chữ ────────────────
class OcrScanResult {
  final Size imageSize;
  final List<OcrBlock> blocks;

  const OcrScanResult({required this.imageSize, required this.blocks});
}

/// Nhận diện chữ trên ảnh. Tách ra để test cubit mà không gọi plugin ML Kit.
abstract class ScanTextRecognizer {
  Future<OcrScanResult> recognize(File imageFile);
}

/// Nhận diện ngôn ngữ của một đoạn chữ. Trả về `null` khi không xác định được.
abstract class ScanLanguageDetector {
  Future<String?> identify(String text);

  Future<void> close();
}

/// Đọc rộng x cao của ảnh đã mã hoá (jpg/png...) mà không giải mã điểm ảnh.
///
/// Đi cùng đường với `ui.instantiateImageCodec` (ImmutableBuffer →
/// ImageDescriptor.encoded) nên ra đúng kích thước mà bản cũ lấy từ
/// `frame.image`, chỉ khác là không giải mã cả ảnh.
Future<Size> readEncodedImageSize(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    return Size(descriptor.width.toDouble(), descriptor.height.toDouble());
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

// ─── Bản thật: ML Kit ────────────────────────────────────────────────────────
class MlKitScanTextRecognizer implements ScanTextRecognizer {
  const MlKitScanTextRecognizer();

  @override
  Future<OcrScanResult> recognize(File imageFile) async {
    final imgSize = await readEncodedImageSize(await imageFile.readAsBytes());

    final recognizer = TextRecognizer(script: TextRecognitionScript.japanese);
    final RecognizedText result;
    try {
      result = await recognizer.processImage(InputImage.fromFile(imageFile));
    } finally {
      await recognizer.close();
    }

    final blocks = <OcrBlock>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final text = element.text.trim();
          if (text.isNotEmpty) {
            blocks.add(OcrBlock(text: text, boundingBox: element.boundingBox));
          }
        }
      }
    }
    return OcrScanResult(imageSize: imgSize, blocks: blocks);
  }
}

/// Giữ một [LanguageIdentifier] suốt vòng đời cubit; đóng trong [close].
class MlKitScanLanguageDetector implements ScanLanguageDetector {
  MlKitScanLanguageDetector();

  LanguageIdentifier? _identifier;
  bool _closed = false;

  @override
  Future<String?> identify(String text) async {
    if (_closed) return null;
    final identifier = _identifier ??= LanguageIdentifier(confidenceThreshold: 0.5);
    final lang = await identifier.identifyLanguage(text);
    return lang == 'und' ? null : lang;
  }

  @override
  Future<void> close() async {
    _closed = true;
    final identifier = _identifier;
    _identifier = null;
    await identifier?.close();
  }
}
