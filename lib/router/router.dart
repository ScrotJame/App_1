
class Routes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String learningHistory = '/learning_history';
  static const String listWord = '/list_word';
  static const String listUnit = '/list_unit';
  static const String addWord = '/add_word';
  static const String test = '/test';
  static const String shop = '/shop';
  static const String scanVocab = '/scan_vocab';
  static const String streak = '/streak';
  static const String companion = '/companion/:userKey';
  static const String inventory = '/inventory';
  static const String achievement = '/achievement';
  static const String backup = '/backup';

  /// Helper to build companion path with actual userKey
  static String companionPath(String userKey) => '/companion/$userKey';
}