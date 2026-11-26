import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../generated/l10n.dart';
import '../helper/review_reminder_planner.dart';
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

  /// Rebuilds the whole review reminder plan from the words' levels, or
  /// removes it when no reviewed word is left. Call it after anything that
  /// changes a word's level or deletes words: studying is what resets the
  /// escalation back to its first tier.
  static Future<void> syncReviewReminder(IVocabularyRepository repo) async {
    if (!_isSupported) return;
    try {
      final reminders = ReviewReminderPlanner.plan(
        reminderTimes: await repo.reviewReminderTimes(),
        now: DateTime.now(),
        messages: reviewReminderMessages(S.current),
        random: Random(),
      );
      if (reminders.isEmpty) {
        await _invoke('cancelReviewAlarm');
      } else {
        await _invoke('scheduleReviewPlan', {
          'reminders': [
            for (final r in reminders)
              <String, Object>{
                'at': r.at.millisecondsSinceEpoch,
                'title': r.title,
                'body': r.body,
              },
          ],
        });
      }
    } catch (e) {
      debugPrint('Review reminder not updated: $e');
    }
  }

  /// Builds the review reminder plan only when Android holds none, e.g.
  /// after an update from a version without plans or a restore. An existing
  /// plan is set again as stored, without being rebuilt: opening the app
  /// must not reset the escalation, only studying does, but a force-stop
  /// drops every alarm while keeping the plan. Needs [S] loaded, since a
  /// missing plan is built here.
  static Future<void> ensureReviewPlan(IVocabularyRepository repo) async {
    if (!_isSupported) return;
    final bool? hasPlan;
    try {
      hasPlan = await _channel.invokeMethod<bool>('hasReviewPlan');
    } catch (e) {
      debugPrint('Review plan not checked: $e');
      return;
    }
    if (hasPlan == false) {
      await syncReviewReminder(repo);
    } else if (hasPlan == true) {
      await _invoke('rearmReviewPlan');
    }
  }

  static ReviewReminderMessages reviewReminderMessages(S s) =>
      ReviewReminderMessages(
        title: s.review_reminder_title,
        bodies: {
          ReminderTier.fresh: [
            s.review_reminder_fresh_1,
            s.review_reminder_fresh_2,
            s.review_reminder_fresh_3,
            s.review_reminder_fresh_4,
            s.review_reminder_fresh_5,
          ],
          ReminderTier.streak: [
            s.review_reminder_streak_1,
            s.review_reminder_streak_2,
            s.review_reminder_streak_3,
            s.review_reminder_streak_4,
            s.review_reminder_streak_5,
          ],
          ReminderTier.fading: [
            s.review_reminder_fading_1,
            s.review_reminder_fading_2,
            s.review_reminder_fading_3,
            s.review_reminder_fading_4,
            s.review_reminder_fading_5,
          ],
          ReminderTier.comeback: [
            s.review_reminder_comeback_1,
            s.review_reminder_comeback_2,
            s.review_reminder_comeback_3,
            s.review_reminder_comeback_4,
            s.review_reminder_comeback_5,
          ],
        },
      );

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
