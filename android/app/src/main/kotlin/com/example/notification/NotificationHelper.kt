package com.example.test_abc

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class NotificationHelper(private val context: Context) {
    private val channelId = "study_alarm_channel"
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Thông báo học tập",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Kênh thông báo cho lịch trình học tập offline"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showNotification(message: String) {
        // 1. Tạo Intent để mở App
        val intent = Intent(context, MainActivity::class.java).apply {
            // Cờ này giúp nếu App đang mở thì nó sẽ đưa App lên phía trước thay vì tạo mới hoàn toàn
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("notification_data", message) // Gửi kèm dữ liệu để Flutter xử lý nếu cần
        }

        // 2. Tạo PendingIntent
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Xây dựng thông báo với ContentIntent
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_logo)
            .setContentTitle("Đã đến giờ học lại!")
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent) // GẮN PENDING INTENT VÀO ĐÂY
            .setAutoCancel(true) // Tự động xóa thông báo khi nhấn vào
            .build()

        notificationManager.notify(message.hashCode(), notification)
    }
}