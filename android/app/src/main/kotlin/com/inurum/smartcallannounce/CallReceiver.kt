package com.inurum.smartcallannounce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.util.Log

class CallReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "CallReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            Log.d(TAG, "Phone state changed: $state, incoming number: $incomingNumber")
            
            val appContext = context.applicationContext
            
            // Critical: goAsync keeps this process alive with foreground priority even in Doze/Idle mode
            val pendingResult = goAsync()
            
            // Acquire CPU wake lock with ACQUIRE_CAUSES_WAKEUP immediately
            AnnouncementManager.acquireWakeLock(appContext)

            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    // Ensure the foreground service is active
                    ensureServiceRunning(appContext)
                    AnnouncementManager.handleIncomingCall(appContext, incomingNumber)
                    
                    // Release pendingResult after ringing completes or safety timeout (20s)
                    Handler(Looper.getMainLooper()).postDelayed({
                        try {
                            pendingResult.finish()
                        } catch (e: Exception) {
                            // Ignored if already finished
                        }
                    }, 20000L)
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK, 
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    Log.d(TAG, "State changed to $state, notifying onCallEnded")
                    AnnouncementManager.onCallEnded(appContext)
                    try {
                        pendingResult.finish()
                    } catch (e: Exception) {
                        // Ignored
                    }
                }
                else -> {
                    try {
                        pendingResult.finish()
                    } catch (e: Exception) {
                        // Ignored
                    }
                }
            }
        }
    }

    private fun ensureServiceRunning(context: Context) {
        try {
            if (SettingsHelper.isAnnouncementEnabled(context)) {
                val serviceIntent = Intent(context, CallAnnounceService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to start service from CallReceiver: ${e.message}")
        }
    }
}

