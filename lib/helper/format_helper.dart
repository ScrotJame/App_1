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

  static String formatNumberPrice(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    if (n >= 10000) {
      return '${(n / 10000).toStringAsFixed(n % 10000 == 0 ? 0 : 1)}m';
    }
    if (n >= 100000) {
      return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}b';
    }
    return n.toString();
  }

}