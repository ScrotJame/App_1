package com.example.test_abc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val message = intent?.getStringExtra("Extra") ?: return
        val contextNonNull = context ?: return

        // Gọi module hiển thị thông báo
        val notificationHelper = NotificationHelper(contextNonNull)
        notificationHelper.showNotification(message)
    }
}