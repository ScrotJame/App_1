import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logic/test_config.dart';

/// Test preferences kept on the device and not backed up: the last setup,
/// and whether the level-down rule has been explained. A read that fails
/// gives the default, a write that fails is skipped.
class TestConfigStore {
  static const configKey = 'test_config';
  static const levelDownExplainedKey = 'test_level_down_explained';

  Future<TestConfig?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(configKey);
      if (raw == null) return null;
      return TestConfig.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TestConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(configKey, jsonEncode(config.toJson()));
    } catch (_) {
      // The setup is a convenience: losing it must not block the test.
    }
  }

  Future<bool> isLevelDownExplained() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(levelDownExplainedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markLevelDownExplained() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(levelDownExplainedKey, true);
    } catch (_) {
      // Showing the note again is harmless.
    }
  }
}
