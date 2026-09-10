package com.inurum.smartcallannounce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action
        Log.d(TAG, "Received boot event: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED || action == "android.intent.action.QUICKBOOT_POWERON") {
            if (SettingsHelper.isAnnouncementEnabled(context)) {
                Log.d(TAG, "Announcement is enabled, starting CallAnnounceService after boot")
                val serviceIntent = Intent(context, CallAnnounceService::class.java)
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start CallAnnounceService on boot: ${e.message}", e)
                }
            } else {
                Log.d(TAG, "Announcement is disabled, skipping service start on boot")
            }
        }
    }
}
