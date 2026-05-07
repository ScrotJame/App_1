part of 'app_cubit.dart';

class AppState extends Equatable {
  final Locale? locale;

  const AppState({this.locale});

  AppState copyWith({Locale? locale, bool clearLocale = false}) {
    return AppState(
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  List<(String, String)> get supportedLanguages =>
      S.delegate.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet()
          .map((code) => (code, languageLabels[code] ?? code))
          .toList();

  static const languageLabels = {
    'en': '🇬🇧 English',
    'vi': '🇻🇳 Tiếng Việt',
    'ja': '🇯🇵 日本語',
    'ko': '🇰🇷 한국어',
    'zh': '🇨🇳 中文',
  };

  @override
  List<Object?> get props => [locale?.languageCode];
}