import 'package:flutter/services.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.test_abc/alarm');

  static Future<void> schedule(String word, int seconds) async {
    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'message': word,
        'delaySeconds': seconds,
      });
    } on PlatformException catch (e) {
      print("Lỗi gọi Native: ${e.message}");
    }
  }
}