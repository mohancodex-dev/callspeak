package com.inurum.smartcallannounce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class UnlockReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "UnlockReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action
        Log.d(TAG, "Received broadcast action: $action")

        if (action == Intent.ACTION_USER_PRESENT) {
            Log.d(TAG, "Device unlocked (ACTION_USER_PRESENT) detected.")
            val pendingResult = goAsync()
            try {
                UnlockCaptureManager.handleUnlockEvent(context)
            } catch (e: Exception) {
                Log.e(TAG, "Error handling unlock event: ${e.message}", e)
            } finally {
                pendingResult.finish()
            }
        }
    }
}
