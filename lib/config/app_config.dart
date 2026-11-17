enum AppFlavor {
  dev,
  prod,
}

class AppConfig {
  /// Login, cloud backup and everything that needs Firebase.
  /// Turning this on also needs per-user backup keys; see the offline release spec.
  static const bool cloudEnabled = false;

  /// Shop and inventory.
  static const bool shopEnabled = false;

  /// Achievements page. Off until unlocking is wired up (report item 4).
  static const bool achievementsEnabled = false;

  /// Companion/pet page, feed bubble and food rewards.
  /// Off until food, XP bonus and unlock level work (report item 5).
  static const bool companionEnabled = false;

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
