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

// ─── Bản thật: ML Kit ────────────────────────────────────────────────────────
class MlKitScanTextRecognizer implements ScanTextRecognizer {
  const MlKitScanTextRecognizer();

  @override
  Future<OcrScanResult> recognize(File imageFile) async {
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
          if (text.isNotEmpty) {
            blocks.add(OcrBlock(text: text, boundingBox: element.boundingBox));
          }
        }
      }
    }
    return OcrScanResult(imageSize: imgSize, blocks: blocks);
  }
}

class MlKitScanLanguageDetector implements ScanLanguageDetector {
  MlKitScanLanguageDetector();

  @override
  Future<String?> identify(String text) async {
    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    final lang = await identifier.identifyLanguage(text);
    await identifier.close();
    return lang == 'und' ? null : lang;
  }

  @override
  Future<void> close() async {}
}
