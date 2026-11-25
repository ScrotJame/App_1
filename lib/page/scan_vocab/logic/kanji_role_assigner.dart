import 'dart:math' as math;
import 'dart:ui';

import '../../../commons/enums.dart';
import 'japanese_text.dart';

/// Một mảnh chữ OCR và khung của nó trên ảnh gốc.
class OcrFragment {
  const OcrFragment(this.text, this.box);

  final String text;
  final Rect box;
}

/// Chia các mảnh được chọn bằng vai trò "Từ" thành từ và cách đọc.
///
/// Không mảnh nào có kanji thì tất cả là từ. Có kanji thì mảnh toàn hiragana
/// là cách đọc, trừ khi nó đứng liền một mảnh từ (okurigana, tiền tố).
List<TokenRole> assignKanjiRoles(List<OcrFragment> fragments) {
  if (!fragments.any((f) => containsHan(f.text))) {
    return List.filled(fragments.length, TokenRole.word);
  }

  final isWord = [
    for (final f in fragments)
      stripBrackets(f.text).isNotEmpty && !isHiraganaReading(f.text),
  ];

  var grew = true;
  while (grew) {
    grew = false;
    for (var i = 0; i < fragments.length; i++) {
      if (isWord[i]) continue;
      final text = fragments[i].text;
      if (hasBrackets(text) || stripBrackets(text).isEmpty) continue;
      for (var j = 0; j < fragments.length; j++) {
        if (isWord[j] && _isSameRun(fragments[i].box, fragments[j].box)) {
          isWord[i] = true;
          grew = true;
          break;
        }
      }
    }
  }

  return [
    for (final word in isWord)
      word ? TokenRole.word : TokenRole.pronunciation,
  ];
}

/// Hai khung cùng cỡ chữ và nằm liền nhau trên một hàng (hoặc một cột dọc).
bool _isSameRun(Rect a, Rect b) {
  final larger = math.max(a.shortestSide, b.shortestSide);
  if (larger <= 0) return false;
  if (math.min(a.shortestSide, b.shortestSide) / larger < 0.7) return false;
  final maxGap = larger * 0.5;

  final overlapY = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
  final gapX = math.max(a.left, b.left) - math.min(a.right, b.right);
  if (overlapY >= 0.5 * math.min(a.height, b.height) && gapX <= maxGap) {
    return true;
  }

  // Xét theo cột chỉ khi có khung rõ là chữ dọc, để hai dòng ngang chồng
  // nhau (từ ở trên, cách đọc ở dưới) không bị gộp.
  final vertical = a.height > a.width * 1.2 || b.height > b.width * 1.2;
  if (!vertical) return false;
  final overlapX = math.min(a.right, b.right) - math.max(a.left, b.left);
  final gapY = math.max(a.top, b.top) - math.min(a.bottom, b.bottom);
  return overlapX >= 0.5 * math.min(a.width, b.width) && gapY <= maxGap;
}
