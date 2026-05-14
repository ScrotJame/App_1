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

}