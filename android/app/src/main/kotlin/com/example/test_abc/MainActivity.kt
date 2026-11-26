package com.example.test_abc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDateTime
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.test_abc/alarm"

    @RequiresApi(Build.VERSION_CODES.O)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val scheduler = AndroidAlarmScheduler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val message = call.argument<String>("message") ?: ""
                    val seconds = call.argument<Int>("delaySeconds") ?: 0

                    // Tính thời gian báo thức: Hiện tại + số giây truyền từ Flutter
                    val alarmTime = LocalDateTime.now().plusSeconds(seconds.toLong())

                    scheduler.schedule(AlarmItem(alarmTime, message))
                    result.success(true)
                }
                "scheduleReviewPlan" -> {
                    val raw = call.argument<List<Map<String, Any?>>>("reminders")
                    if (raw == null) {
                        result.error("bad_args", "reminders is required", null)
                    } else {
                        val reminders = raw.mapNotNull { item ->
                            val at = (item["at"] as? Number)?.toLong() ?: return@mapNotNull null
                            ReviewReminder(
                                at,
                                item["title"] as? String ?: "",
                                item["body"] as? String ?: ""
                            )
                        }
                        scheduler.scheduleReviewPlan(reminders)
                        result.success(true)
                    }
                }
                "cancelReviewAlarm" -> {
                    scheduler.cancelReview()
                    result.success(true)
                }
                "hasReviewPlan" -> result.success(scheduler.hasReviewPlan())
                else -> result.notImplemented()
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