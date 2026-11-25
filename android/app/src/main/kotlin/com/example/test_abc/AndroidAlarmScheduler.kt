package com.example.test_abc

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.time.ZoneId

class AndroidAlarmScheduler(private val context: Context) : AlarmScheduler {

    private val alarmManager = context.getSystemService(AlarmManager::class.java)
    private val store = ReviewPlanStore(context)

    override fun schedule(item: AlarmItem) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("Extra", item.message)
        }
        val triggerTimeMilli = item.time.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            item.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        setAlarm(triggerTimeMilli, pendingIntent)
    }

    override fun scheduleReviewPlan(reminders: List<ReviewReminder>) {
        cancelReviewAlarms()
        reminders.take(MAX_REVIEW_REMINDERS).forEachIndexed { index, reminder ->
            setAlarm(reminder.atMillis, reviewPendingIntent(index, reminder))
        }
        store.save(reminders.take(MAX_REVIEW_REMINDERS))
    }

    override fun cancelReview() {
        cancelReviewAlarms()
        store.clear()
    }

    override fun rearmFromStore(nowMillis: Long) {
        store.load().forEachIndexed { index, reminder ->
            if (reminder.atMillis > nowMillis) {
                setAlarm(reminder.atMillis, reviewPendingIntent(index, reminder))
            }
        }
    }

    /**
     * Exact when the user allows it; otherwise an inexact alarm, because
     * setExactAndAllowWhileIdle throws on Android 12+ without the permission.
     */
    private fun setAlarm(atMillis: Long, pendingIntent: PendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pendingIntent)
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pendingIntent)
        }
    }

    /**
     * Cancels by request code, not by the stored plan, so a lost or broken
     * store cannot leave alarms behind. Also drops the single alarm older
     * versions set.
     */
    private fun cancelReviewAlarms() {
        for (index in 0 until MAX_REVIEW_REMINDERS) {
            existing(REVIEW_REQUEST_CODE_BASE + index, reviewIntent(null))?.let {
                alarmManager.cancel(it)
                it.cancel()
            }
        }
        existing(LEGACY_REVIEW_REQUEST_CODE, Intent(context, AlarmReceiver::class.java))?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }

    private fun existing(requestCode: Int, intent: Intent): PendingIntent? =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )

    private fun reviewPendingIntent(index: Int, reminder: ReviewReminder): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            REVIEW_REQUEST_CODE_BASE + index,
            reviewIntent(reminder),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

    /** Extras do not take part in matching, so cancel can pass null. */
    private fun reviewIntent(reminder: ReviewReminder?): Intent =
        Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_REVIEW
            if (reminder != null) {
                putExtra(EXTRA_TITLE, reminder.title)
                putExtra(EXTRA_BODY, reminder.body)
            }
        }

    companion object {
        const val ACTION_REVIEW = "com.example.test_abc.REVIEW_REMINDER"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        /** The planner makes at most 66; this leaves room. */
        private const val MAX_REVIEW_REMINDERS = 100
        private const val REVIEW_REQUEST_CODE_BASE = 2000
        private const val LEGACY_REVIEW_REQUEST_CODE = 1001
    }
}
