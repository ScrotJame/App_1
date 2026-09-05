enum AppFlavor {
  dev,
  prod,
}

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String envFileName;

  static AppConfig? _instance;

  AppConfig({
    required this.flavor,
    required this.appName,
    required this.envFileName,
  });

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig has not been initialized. Please call AppConfig.setInstance before accessing.',
      );
    }
    return _instance!;
  }

  static void setInstance(AppConfig config) {
    _instance = config;
  }

  bool get isDev => flavor == AppFlavor.dev;
  bool get isProd => flavor == AppFlavor.prod;
}
