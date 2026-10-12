package com.inurum.smartcallannounce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
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
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "CallSpeak:UnlockReceiverWakeLock"
            )?.apply {
                acquire(10000L) // 10 seconds max safety timeout
            }

            try {
                UnlockCaptureManager.handleUnlockEvent(context) {
                    try {
                        if (wakeLock?.isHeld == true) {
                            wakeLock.release()
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error releasing WakeLock: ${e.message}")
                    }
                    try {
                        pendingResult.finish()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error finishing pendingResult: ${e.message}")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error initiating unlock event handling: ${e.message}", e)
                try {
                    if (wakeLock?.isHeld == true) {
                        wakeLock.release()
                    }
                } catch (we: Exception) {
                    // Ignore
                }
                try {
                    pendingResult.finish()
                } catch (pe: Exception) {
                    // Ignore
                }
            }
        }
    }
}
