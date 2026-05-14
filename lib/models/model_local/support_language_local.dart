class SupportedLanguage {
  final String code;
  final String label;
  final String flag;

  const SupportedLanguage({required this.code, required this.label, required this.flag});
}

const kSupportedLanguages = [
  SupportedLanguage(code: 'ja', label: 'Tiếng Nhật',   flag: '🇯🇵'),
  SupportedLanguage(code: 'zh', label: 'Tiếng Trung',  flag: '🇨🇳'),
  SupportedLanguage(code: 'ko', label: 'Tiếng Hàn',    flag: '🇰🇷'),
  SupportedLanguage(code: 'en', label: 'Tiếng Anh',    flag: '🇬🇧'),
  SupportedLanguage(code: 'fr', label: 'Tiếng Pháp',   flag: '🇫🇷'),
  SupportedLanguage(code: 'de', label: 'Tiếng Đức',    flag: '🇩🇪'),
  SupportedLanguage(code: 'es', label: 'Tiếng Tây Ban Nha', flag: '🇪🇸'),
  SupportedLanguage(code: 'vi', label: 'Tiếng Việt',   flag: '🇻🇳'),
  SupportedLanguage(code: 'ru', label: 'Tiếng Nga',    flag: '🇷🇺'),
  SupportedLanguage(code: 'th', label: 'Tiếng Thái',   flag: '🇹🇭'),
];
