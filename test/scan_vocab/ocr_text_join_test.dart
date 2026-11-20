import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/scan_vocab/ocr_text_join.dart';

void main() {
  group('joinOcrTokens', () {
    test('rỗng', () {
      expect(joinOcrTokens(const []), '');
    });

    test('toàn kanji/kana nối liền', () {
      expect(joinOcrTokens(['食べ', '物']), '食べ物');
      expect(joinOcrTokens(['たべ', 'もの']), 'たべもの');
      expect(joinOcrTokens(['カタ', 'カナ', '語']), 'カタカナ語');
      expect(joinOcrTokens(['東京', '、', '大阪']), '東京、大阪');
    });

    test('chữ Hán Trung và chữ Hán mở rộng (ngoài BMP) nối liền', () {
      expect(joinOcrTokens(['学习', '中文']), '学习中文');
      expect(joinOcrTokens(['𠮷', '野家']), '𠮷野家');
    });

    test('kana nửa độ rộng / ký tự toàn độ rộng nối liền', () {
      expect(joinOcrTokens(['ｶﾀ', 'ｶﾅ']), 'ｶﾀｶﾅ');
      expect(joinOcrTokens(['（', '注', '）']), '（注）');
    });

    test('toàn Latin giữ dấu cách', () {
      expect(joinOcrTokens(['to', 'eat']), 'to eat');
      expect(joinOcrTokens(['ăn', 'uống']), 'ăn uống');
    });

    test('Hangul giữ dấu cách (tiếng Hàn dùng dấu cách giữa các từ)', () {
      expect(joinOcrTokens(['먹다', '음식']), '먹다 음식');
    });

    test('trộn: chỉ nối liền khi cả hai phía đều là CJK', () {
      expect(joinOcrTokens(['Tokyo', 'タワー']), 'Tokyo タワー');
      expect(joinOcrTokens(['食べ', '物', 'food']), '食べ物 food');
      expect(joinOcrTokens(['日本', '語', 'N5', 'レベル']), '日本語 N5 レベル');
      expect(joinOcrTokens(['東京', '(とうきょう)']), '東京 (とうきょう)');
    });

    test('bỏ qua mảnh rỗng / chỉ có khoảng trắng', () {
      expect(joinOcrTokens(['食べ', ' ', '', '物']), '食べ物');
      expect(joinOcrTokens([' to ', 'eat']), 'to eat');
    });
  });
}
