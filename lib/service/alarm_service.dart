import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../generated/l10n.dart';
import '../repository/vocabulary_repository.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.test_abc/alarm');

  /// Only Android has a native handler for the alarm channel.
  static bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> schedule(String word, int seconds) async {
    await _invoke('scheduleAlarm', {
      'message': word,
      'delaySeconds': seconds,
    });
  }

  /// Points the app's single review reminder at the next word that becomes
  /// due, or removes it when no reviewed word is left. Call it after anything
  /// that changes a word's level or deletes words.
  static Future<void> syncReviewReminder(IVocabularyRepository repo) async {
    if (!_isSupported) return;
    try {
      final time = await repo.nextReviewReminderTime();
      if (time == null) {
        await _invoke('cancelReviewAlarm');
      } else {
        await _invoke('scheduleReviewAlarm', {
          'message': S.current.review_reminder_message,
          'triggerAtMillis': time.millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint('Review reminder not updated: $e');
    }
  }

  static Future<void> _invoke(String method, [Map<String, Object>? arguments]) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod(method, arguments);
    } on PlatformException catch (e) {
      debugPrint('Lỗi gọi Native: ${e.message}');
    } on MissingPluginException catch (e) {
      debugPrint('Lỗi gọi Native: ${e.message}');
    }
  }
}
