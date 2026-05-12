class FormatHelper {


  static String formatPrice(num price) {
    final str = price.toInt().toString();
    if (str.length <= 3) return str;
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

}