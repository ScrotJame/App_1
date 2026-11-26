import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/service/alarm_service.dart';

class _MockVocabularyRepository extends Mock implements IVocabularyRepository {}

/// At start the plan is built only when Android has none, so opening the app
/// never resets the escalation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const alarmChannel = MethodChannel('com.example.test_abc/alarm');

  late _MockVocabularyRepository vocabulary;
  late List<MethodCall> calls;
  late Object? Function(MethodCall call) answer;

  List<String> methods() => calls.map((c) => c.method).toList();

  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    vocabulary = _MockVocabularyRepository();
    when(() => vocabulary.reviewReminderTimes()).thenAnswer(
      (_) async => [DateTime.now().add(const Duration(hours: 1))],
    );
    calls = [];
    answer = (_) => true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, (call) async {
      calls.add(call);
      return answer(call);
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, null);
  });

  void hasReviewPlanAnswers(Object? value) {
    answer = (call) => call.method == 'hasReviewPlan' ? value : true;
  }

  test('no stored plan: the plan is built and sent', () async {
    hasReviewPlanAnswers(false);

    await AlarmService.ensureReviewPlan(vocabulary);

    expect(methods(), ['hasReviewPlan', 'scheduleReviewPlan']);
    final reminders = (calls.last.arguments as Map)['reminders'] as List;
    expect(reminders, isNotEmpty);
  });

  test('no stored plan and no reviewed word: the alarms are cancelled',
      () async {
    hasReviewPlanAnswers(false);
    when(() => vocabulary.reviewReminderTimes()).thenAnswer((_) async => []);

    await AlarmService.ensureReviewPlan(vocabulary);

    expect(methods(), ['hasReviewPlan', 'cancelReviewAlarm']);
  });

  test('a stored plan is set again as stored, not rebuilt', () async {
    hasReviewPlanAnswers(true);

    await AlarmService.ensureReviewPlan(vocabulary);

    expect(methods(), ['hasReviewPlan', 'rearmReviewPlan']);
    verifyNever(() => vocabulary.reviewReminderTimes());
  });

  test('a null answer changes nothing', () async {
    hasReviewPlanAnswers(null);

    await AlarmService.ensureReviewPlan(vocabulary);

    expect(methods(), ['hasReviewPlan']);
  });

  test('a native error changes nothing and does not throw', () async {
    answer = (call) => throw PlatformException(code: 'boom');

    await expectLater(AlarmService.ensureReviewPlan(vocabulary), completes);

    expect(methods(), ['hasReviewPlan']);
    verifyNever(() => vocabulary.reviewReminderTimes());
  });

  test('a missing native handler does not throw', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, null);

    await expectLater(AlarmService.ensureReviewPlan(vocabulary), completes);

    verifyNever(() => vocabulary.reviewReminderTimes());
  });

  test('nothing is asked on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await AlarmService.ensureReviewPlan(vocabulary);

    expect(calls, isEmpty);
  });
}
