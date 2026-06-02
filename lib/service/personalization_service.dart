import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationService {
  static const String _keyDailyWordTarget = 'pref_daily_word_target';
  static const String _keyCompanionAlignment = 'pref_companion_alignment';
  static const String _keyPersonalizationMultiplier = 'pref_personalization_multiplier';
  static const String _keyStudySessionCount = 'pref_study_session_count';

  static final PersonalizationService instance = PersonalizationService._();
  PersonalizationService._();

  late final SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Get daily target word count (SM-2 review queue)
  int getDailyWordTarget() {
    return _prefs.getInt(_keyDailyWordTarget) ?? 20;
  }

  /// Set daily target word count
  Future<bool> setDailyWordTarget(int count) async {
    return _prefs.setInt(_keyDailyWordTarget, count);
  }

  /// Check if companion integration / alignment is active
  bool isCompanionAlignmentEnabled() {
    return _prefs.getBool(_keyCompanionAlignment) ?? true;
  }

  /// Enable or disable companion learning alignment
  Future<bool> setCompanionAlignmentEnabled(bool enabled) async {
    return _prefs.setBool(_keyCompanionAlignment, enabled);
  }

  /// Get personalization scale factor (0.0 to 1.0)
  double getPersonalizationMultiplier() {
    return _prefs.getDouble(_keyPersonalizationMultiplier) ?? 1.0;
  }

  /// Set personalization scale factor
  Future<bool> setPersonalizationMultiplier(double value) async {
    return _prefs.setDouble(_keyPersonalizationMultiplier, value);
  }

  /// Log custom study count
  int getStudySessionCount() {
    return _prefs.getInt(_keyStudySessionCount) ?? 0;
  }

  /// Increment custom study count
  Future<bool> incrementStudySessionCount() async {
    final current = getStudySessionCount();
    return _prefs.setInt(_keyStudySessionCount, current + 1);
  }
}
