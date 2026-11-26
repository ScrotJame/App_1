package com.example.test_abc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val contextNonNull = context ?: return
        val intentNonNull = intent ?: return
        val notificationHelper = NotificationHelper(contextNonNull)

        if (intentNonNull.action == AndroidAlarmScheduler.ACTION_REVIEW) {
            val title = intentNonNull.getStringExtra(AndroidAlarmScheduler.EXTRA_TITLE) ?: return
            val body = intentNonNull.getStringExtra(AndroidAlarmScheduler.EXTRA_BODY) ?: return
            notificationHelper.showReview(title, body)
            return
        }

        val message = intentNonNull.getStringExtra("Extra") ?: return
        notificationHelper.showNotification(message)
    }
}
