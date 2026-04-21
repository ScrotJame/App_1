package com.example.test_abc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDateTime
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.test_abc/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val scheduler = AndroidAlarmScheduler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scheduleAlarm") {
                val message = call.argument<String>("message") ?: ""
                val seconds = call.argument<Int>("delaySeconds") ?: 0

                // Tính thời gian báo thức: Hiện tại + số giây truyền từ Flutter
                val alarmTime = LocalDateTime.now().plusSeconds(seconds.toLong())

                scheduler.schedule(AlarmItem(alarmTime, message))
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val data = intent.getStringExtra("notification_data")
        if (data != null) {
            // Gửi dữ liệu qua Flutter để xử lý điều hướng
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, "com.example.test_abc/alarm")
                .invokeMethod("onNotificationClicked", data)
        }
    }

}