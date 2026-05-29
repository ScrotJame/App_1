class LanguageHelper {

  static String getDetectedLanguageLabel(String? detectedLanguage) {
    switch (detectedLanguage) {
      case 'ja': return '🇯🇵 Tiếng Nhật';
      case 'en': return '🇬🇧 Tiếng Anh';
      case 'zh': return '🇨🇳 Tiếng Trung';
      case 'ko': return '🇰🇷 Tiếng Hàn';
      case 'vi': return '🇻🇳 Tiếng Việt';
      default:   return detectedLanguage ?? '';
    }
  }

  static String getDetectedLanguageLabelTag(String? detectedLanguage) {
    switch (detectedLanguage) {
      case 'ja': return 'Tiếng Nhật';
      case 'en': return 'Tiếng Anh';
      case 'zh': return 'Tiếng Trung';
      case 'ko': return 'Tiếng Hàn';
      case 'vi': return 'Tiếng Việt';
      case 'ru': return 'Tiếng Nga';
      case 'th': return 'Tiếng Thái';
      case 'fr': return 'Tiếng Pháp';
      case 'da': return 'Tiếng Đan Mạch';
      case 'de': return 'Tiếng Đức';
      case 'es': return 'Tiếng Tây Ban Nha';
      default: return 'Tất cả';
    }
  }

}