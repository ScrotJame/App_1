package com.example.test_abc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Android drops every alarm on reboot; set the stored review plan again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val contextNonNull = context ?: return
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            ACTION_QUICKBOOT_POWERON,
            Intent.ACTION_MY_PACKAGE_REPLACED ->
                AndroidAlarmScheduler(contextNonNull).rearmFromStore(System.currentTimeMillis())
        }
    }

    companion object {
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
    }
}
