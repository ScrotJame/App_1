package com.example.test_abc

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.time.ZoneId

class AndroidAlarmScheduler(private val context: Context) : AlarmScheduler {

    private val alarmManager = context.getSystemService(AlarmManager::class.java)

    override fun schedule(item: AlarmItem) {
        // 1. Tạo Intent trỏ tới AlarmReceiver
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("Extra", item.message)
        }

        // 2. Chuyển LocalDateTime sang Miliseconds (Đơn vị AlarmManager yêu cầu)
        val triggerTimeMilli = item.time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()

        // 3. Tạo PendingIntent (Tham số thứ 3 phải là intent)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            item.hashCode(), // ID duy nhất để không bị đè thông báo khác
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 4. Đặt báo thức chính xác (Xuyên qua cả chế độ tiết kiệm pin Doze Mode)
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerTimeMilli,
            pendingIntent
        )
    }

    override fun scheduleReview(triggerAtMillis: Long, message: String) {
        // Cùng request code nên lần đặt sau thay cho lần trước.
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            reviewPendingIntent(message)
        )
    }

    override fun cancelReview() {
        alarmManager.cancel(reviewPendingIntent(""))
    }

    private fun reviewPendingIntent(message: String): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("Extra", message)
        }
        return PendingIntent.getBroadcast(
            context,
            REVIEW_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    companion object {
        private const val REVIEW_REQUEST_CODE = 1001
    }

}