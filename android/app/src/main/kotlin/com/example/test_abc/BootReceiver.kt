package com.example.test_abc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/** Android drops every alarm on reboot; set the stored review plan again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val contextNonNull = context ?: return
        val action = intent?.action
        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            ACTION_QUICKBOOT_POWERON,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                // A crash here would take the whole process down at boot.
                try {
                    val scheduler = AndroidAlarmScheduler(contextNonNull)
                    if (action == Intent.ACTION_MY_PACKAGE_REPLACED) {
                        // Alarms survive an update, so the old single alarm
                        // would keep firing next to the new plan.
                        runLogged("cancel legacy review alarm") {
                            scheduler.cancelLegacyReviewAlarm()
                        }
                    }
                    runLogged("re-arm review plan") {
                        scheduler.rearmFromStore(System.currentTimeMillis())
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Review alarms not restored on $action", e)
                }
            }
        }
    }

    private fun runLogged(what: String, block: () -> Unit) {
        try {
            block()
        } catch (e: Exception) {
            Log.e(TAG, "Could not $what", e)
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
    }
}
