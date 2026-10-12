package com.inurum.smartcallannounce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.PowerManager
import android.util.Log
import androidx.core.content.ContextCompat

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
            if (!UnlockCaptureManager.isFeatureEnabled(context)) {
                Log.d(TAG, "Unlock capture feature is disabled in settings. Skipping.")
                return
            }

            val hasCameraPermission = ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
            if (!hasCameraPermission) {
                Log.w(TAG, "Camera permission not granted on unlock.")
                return
            }

            val pendingResult = goAsync()
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "CallSpeak:UnlockReceiverWakeLock"
            )?.apply {
                acquire(10000L)
            }

            fun complete() {
                try {
                    if (wakeLock?.isHeld == true) {
                        wakeLock.release()
                    }
                } catch (e: Exception) {
                    // Ignore
                }
                try {
                    pendingResult.finish()
                } catch (e: Exception) {
                    // Ignore
                }
            }

            try {
                if (UnlockCaptureManager.isAppInForeground(context)) {
                    Log.d(TAG, "App is in foreground, capturing directly")
                    UnlockCaptureManager.handleUnlockEvent(context) { complete() }
                } else {
                    Log.d(TAG, "App is terminated/background, starting UnlockCaptureService with camera type")
                    UnlockCaptureService.start(context)
                    complete()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error initiating unlock capture: ${e.message}", e)
                try {
                    val actIntent = Intent(context, UnlockCaptureActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_NO_ANIMATION or
                                Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                    }
                    context.startActivity(actIntent)
                } catch (ae: Exception) {
                    Log.e(TAG, "Fallback activity launch failed: ${ae.message}")
                }
                complete()
            }
        }
    }
}
