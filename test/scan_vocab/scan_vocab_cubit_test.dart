import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/scan_vocab/scan_vocab_cubit.dart';

import 'scan_vocab_test_support.dart';

void main() {
  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  late FakeTextRecognizer recognizer;
  late FakeLanguageDetector detector;
  late ScanVocabCubit cubit;

  // Ảnh 200x100 hiển thị trong vùng 100x50 lệch (10, 20) → hệ số 2.
  const displayRect = Rect.fromLTWH(10, 20, 100, 50);
  const widgetSize = Size(120, 90);

  Future<void> scan(List<OcrBlock> blocks, {Size size = const Size(200, 100)}) async {
    recognizer.result = OcrScanResult(imageSize: size, blocks: blocks);
    await cubit.runOcr(dummyFile);
  }

  setUp(() {
    recognizer = FakeTextRecognizer();
    detector = FakeLanguageDetector();
    cubit = ScanVocabCubit(recognizer: recognizer, languageDetector: detector);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('kéo chọn', () {
    test('kéo lên/sang trái giữ nguyên điểm gốc', () {
      cubit.startDrag(const Offset(100, 100));
      cubit.updateDrag(const Offset(40, 30));
      expect(cubit.state.dragRect, const Rect.fromLTRB(40, 30, 100, 100));

      cubit.updateDrag(const Offset(120, 50));
      expect(cubit.state.dragRect, const Rect.fromLTRB(100, 50, 120, 100));
      expect(cubit.state.dragOrigin, const Offset(100, 100));
    });

    test('updateDrag không làm gì khi chưa startDrag', () {
      cubit.updateDrag(const Offset(40, 30));
      expect(cubit.state.dragRect, isNull);
    });

    test('endDrag chọn các mảnh giao vùng kéo theo toạ độ ảnh và xoá vùng kéo', () async {
      await scan([
        block('A', 0, 0, 20, 20), // widget: (10,20)-(20,30)
        block('B', 180, 80, 200, 100), // widget: (100,60)-(110,70)
      ]);
      // Kéo ngược từ dưới phải lên trên trái, chỉ bao A.
      cubit.startDrag(const Offset(25, 35));
      cubit.updateDrag(const Offset(5, 15));
      cubit.endDrag(widgetSize, displayRect);

      expect(cubit.state.blocks[0].isSelected, isTrue);
      expect(cubit.state.blocks[0].role, TokenRole.word);
      expect(cubit.state.blocks[1].isSelected, isFalse);
      expect(cubit.state.dragRect, isNull);
      expect(cubit.state.dragOrigin, isNull);
    });

    test('endDrag khi chưa có ảnh vẫn xoá vùng kéo', () {
      cubit.startDrag(const Offset(5, 5));
      cubit.updateDrag(const Offset(30, 30));
      cubit.endDrag(widgetSize, displayRect);
      expect(cubit.state.dragRect, isNull);
      expect(cubit.state.dragOrigin, isNull);
    });
  });

  group('chạm chọn', () {
    test('chạm vào mảnh thì chọn, chạm lại thì bỏ chọn', () async {
      await scan([block('A', 0, 0, 20, 20), block('B', 100, 40, 140, 60)]);

      // Điểm widget (70, 45) → ảnh (120, 50): nằm trong B.
      cubit.tapAt(const Offset(70, 45), displayRect);
      expect(cubit.state.blocks[1].isSelected, isTrue);
      expect(cubit.state.blocks[1].role, TokenRole.word);
      expect(cubit.state.blocks[0].isSelected, isFalse);

      cubit.tapAt(const Offset(70, 45), displayRect);
      expect(cubit.state.blocks[1].isSelected, isFalse);
      expect(cubit.state.blocks[1].role, TokenRole.none);
    });

    test('chạm mảnh đã chọn bằng vai trò khác thì đổi vai trò', () async {
      await scan([block('A', 0, 0, 20, 20)]);
      cubit.tapAt(const Offset(15, 25), displayRect);
      cubit.setActiveRole(TokenRole.meaning);
      cubit.tapAt(const Offset(15, 25), displayRect);
      expect(cubit.state.blocks[0].isSelected, isTrue);
      expect(cubit.state.blocks[0].role, TokenRole.meaning);
    });

    test('chạm chỗ trống xa mọi mảnh thì không đổi gì', () async {
      await scan([block('A', 0, 0, 20, 20)]);
      final before = cubit.state.blocks;
      cubit.tapAt(const Offset(100, 65), displayRect);
      expect(cubit.state.blocks, before);
    });

    test('chạm hai mảnh chồng nhau thì chọn mảnh nhỏ hơn', () async {
      await scan([block('Big', 0, 0, 100, 100), block('Small', 40, 40, 60, 60)]);
      // widget (35, 45) → ảnh (50, 50)
      cubit.tapAt(const Offset(35, 45), displayRect);
      expect(cubit.state.blocks[1].isSelected, isTrue);
      expect(cubit.state.blocks[0].isSelected, isFalse);
    });

    test('tapBlock bỏ qua chỉ số ngoài phạm vi', () async {
      await scan([block('A', 0, 0, 20, 20)]);
      cubit.tapBlock(5);
      cubit.tapBlock(-1);
      expect(cubit.state.blocks.single.isSelected, isFalse);
    });
  });

  group('kết quả quét', () {
    test('lỗi OCR → status error kèm thông báo', () async {
      recognizer.error = Exception('boom');
      await cubit.runOcr(dummyFile);
      expect(cubit.state.status, SCANSTATUS.error);
      expect(cubit.state.errorText, contains('boom'));
      expect(cubit.state.hasNoText, isFalse);
    });

    test('ảnh không có chữ → scanned và hasNoText', () async {
      await scan([]);
      expect(cubit.state.status, SCANSTATUS.scanned);
      expect(cubit.state.hasNoText, isTrue);
      expect(cubit.state.errorText, isEmpty);
    });

    test('quét lại sau lỗi xoá thông báo lỗi', () async {
      recognizer.error = Exception('boom');
      await cubit.runOcr(dummyFile);
      recognizer.error = null;
      await scan([block('A', 0, 0, 20, 20)]);
      expect(cubit.state.status, SCANSTATUS.scanned);
      expect(cubit.state.errorText, isEmpty);
      expect(cubit.state.hasNoText, isFalse);
    });
  });

  group('ngôn ngữ', () {
    test('chọn tay được giữ sau khi Thêm', () async {
      await scan([block('食べ', 0, 0, 20, 20), block('food', 100, 40, 140, 60)]);
      cubit.setLanguageManually('zh');
      cubit.tapAt(const Offset(15, 25), displayRect);
      cubit.setActiveRole(TokenRole.meaning);
      cubit.tapAt(const Offset(70, 45), displayRect);

      expect(cubit.takeCurrentItem()?.language, 'zh');
      expect(cubit.state.detectedLanguage, 'zh');
      expect(cubit.state.isLanguageManuallySet, isTrue);
    });

    test('chọn tay được giữ sau khi xoá lựa chọn', () async {
      await scan([block('食べ', 0, 0, 20, 20)]);
      cubit.setLanguageManually('zh');
      cubit.tapAt(const Offset(15, 25), displayRect);
      cubit.clearRole(TokenRole.word);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.detectedLanguage, 'zh');
      cubit.clearAllSelections();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.detectedLanguage, 'zh');
      expect(cubit.state.isLanguageManuallySet, isTrue);
    });

    test('tự động: ngôn ngữ được xoá sau khi Thêm', () async {
      await scan([block('食べ', 0, 0, 20, 20)]);
      cubit.tapAt(const Offset(15, 25), displayRect);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.detectedLanguage, 'ja');

      expect(cubit.takeCurrentItem()?.language, 'ja');
      expect(cubit.state.detectedLanguage, isNull);
      expect(cubit.state.isLanguageManuallySet, isFalse);
    });

    test('useAutoLanguage bỏ cờ chọn tay và nhận diện lại', () async {
      await scan([block('食べ', 0, 0, 20, 20)]);
      cubit.tapAt(const Offset(15, 25), displayRect);
      cubit.setLanguageManually('en');
      expect(cubit.state.detectedLanguage, 'en');

      detector.asked.clear();
      await cubit.useAutoLanguage();
      expect(detector.asked, ['食べ']);
      expect(cubit.state.isLanguageManuallySet, isFalse);
      expect(cubit.state.detectedLanguage, 'ja');
    });

    test('đổi ảnh thì bỏ ngôn ngữ chọn tay', () async {
      await scan([block('食べ', 0, 0, 20, 20)]);
      cubit.setLanguageManually('zh');
      await scan([block('x', 0, 0, 20, 20)]);
      expect(cubit.state.isLanguageManuallySet, isFalse);
      expect(cubit.state.detectedLanguage, isNull);
    });
  });

  group('tự chia kanji / hiragana', () {
    final furigana = [
      block('たべる', 0, 0, 30, 10), // widget (10,20)-(25,25)
      block('食べる', 0, 12, 60, 32), // widget (10,26)-(40,36)
    ];

    test('kéo cả furigana và chữ kanji', () async {
      await scan(furigana);
      cubit.startDrag(const Offset(9, 19));
      cubit.updateDrag(const Offset(45, 40));
      cubit.endDrag(widgetSize, displayRect);

      expect(cubit.state.currentPreview.word, '食べる');
      expect(cubit.state.currentPreview.pronunciation, 'たべる');
    });

    test('chạm từng mảnh cũng chia; đổi tay thì giữ nguyên', () async {
      await scan([...furigana, block('x', 150, 70, 170, 90)]);
      cubit.tapAt(const Offset(15, 22), displayRect);
      expect(cubit.state.blocks[0].role, TokenRole.word);
      cubit.tapAt(const Offset(25, 31), displayRect);
      expect(cubit.state.blocks[0].role, TokenRole.pronunciation);

      cubit.tapAt(const Offset(15, 22), displayRect); // đổi tay thành Từ
      expect(cubit.state.blocks[0].role, TokenRole.word);
      cubit.tapAt(const Offset(90, 60), displayRect); // chọn thêm 'x'
      expect(cubit.state.blocks[0].role, TokenRole.word);
    });

    test('tách chữ trong ngoặc', () async {
      await scan([block('食べる（たべる）', 0, 0, 80, 20)]);
      cubit.tapBlock(0);
      expect(cubit.state.currentPreview.word, '食べる');
      expect(cubit.state.currentPreview.pronunciation, 'たべる');
    });

    test('không tách ngoặc khi không phải kana', () async {
      await scan([block('go (went)', 0, 0, 80, 20)]);
      cubit.tapBlock(0);
      expect(cubit.state.currentPreview.word, 'go (went)');
      expect(cubit.state.currentPreview.pronunciation, '');
    });
  });

  group('sửa tại chỗ', () {
    test('chữ đã sửa giữ tới khi lựa chọn của vai trò đó đổi', () async {
      await scan([
        block('A', 0, 0, 20, 20),
        block('B', 100, 40, 140, 60),
        block('C', 150, 70, 170, 90),
      ]);
      cubit.tapBlock(0);
      cubit.editField(TokenRole.word, ' sửa ');
      expect(cubit.state.currentPreview.word, 'sửa');

      cubit.setActiveRole(TokenRole.meaning);
      cubit.tapBlock(1);
      expect(cubit.state.currentPreview.word, 'sửa');

      cubit.setActiveRole(TokenRole.word);
      cubit.tapBlock(2);
      expect(cubit.state.currentPreview.word, 'A C');
    });

    test('bỏ vai trò xoá luôn chữ đã sửa', () async {
      await scan([block('A', 0, 0, 20, 20)]);
      cubit.editField(TokenRole.meaning, 'nghĩa');
      expect(cubit.state.hasAnySelection, isTrue);
      cubit.clearRole(TokenRole.meaning);
      expect(cubit.state.currentPreview.meaning, '');
      expect(cubit.state.hasAnySelection, isFalse);
    });

    test('takeCurrentItem lấy chữ gõ tay rồi làm trống', () async {
      await scan([block('A', 0, 0, 20, 20)]);
      cubit.editField(TokenRole.word, '猫');
      cubit.editField(TokenRole.meaning, 'mèo');

      final item = cubit.takeCurrentItem();

      expect(item?.word, '猫');
      expect(item?.meaning, 'mèo');
      expect(item?.language, 'ja');
      expect(cubit.state.currentPreview.word, '');
      expect(cubit.state.edits, isEmpty);
    });

    test('takeCurrentItem trả null khi thiếu cả từ lẫn nghĩa', () async {
      await scan([block('A', 0, 0, 20, 20)]);
      cubit.editField(TokenRole.pronunciation, 'a');
      expect(cubit.takeCurrentItem(), isNull);
    });
  });

  group('quy tắc tiếng Nhật', () {
    test('chỉ kanji mà nhận là zh thì thành ja', () async {
      detector.answer = (_) => 'zh';
      await scan([block('学生', 0, 0, 20, 20)]);
      cubit.tapBlock(0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.detectedLanguage, 'ja');
    });

    test('một chữ kanji vẫn nhận là ja', () async {
      await scan([block('猫', 0, 0, 20, 20)]);
      cubit.tapBlock(0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.detectedLanguage, 'ja');
    });
  });
}
