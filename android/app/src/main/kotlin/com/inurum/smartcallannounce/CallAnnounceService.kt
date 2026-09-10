package com.inurum.smartcallannounce

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.NotificationCompat

class CallAnnounceService : Service() {
    companion object {
        private const val TAG = "CallAnnounceService"
        private const val CHANNEL_ID = "CallAnnounceServiceChannel"
        private const val NOTIFICATION_ID = 1001
    }

    private var telephonyManager: TelephonyManager? = null
    private var legacyPhoneStateListener: PhoneStateListener? = null
    private var modernTelephonyCallback: Any? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "CallAnnounceService onCreate")
        AnnouncementManager.initTts(this)
        createNotificationChannel()

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Smart Call Announce")
            .setContentText("Announcer is active in the background")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground with MEDIA_PLAYBACK type, falling back", e)
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (e2: Exception) {
                Log.e(TAG, "Fallback startForeground also failed", e2)
            }
        }

        registerTelephonyListener()
    }

    private fun registerTelephonyListener() {
        try {
            telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager == null) return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val callback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                    override fun onCallStateChanged(state: Int) {
                        handleTelephonyState(state, null)
                    }
                }
                modernTelephonyCallback = callback
                telephonyManager?.registerTelephonyCallback(mainExecutor, callback)
                Log.d(TAG, "Registered modern TelephonyCallback")
            } else {
                @Suppress("DEPRECATION")
                legacyPhoneStateListener = object : PhoneStateListener() {
                    @Deprecated("Deprecated in Java")
                    override fun onCallStateChanged(state: Int, incomingNumber: String?) {
                        handleTelephonyState(state, incomingNumber)
                    }
                }
                @Suppress("DEPRECATION")
                telephonyManager?.listen(legacyPhoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
                Log.d(TAG, "Registered legacy PhoneStateListener")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error registering telephony listener: ${e.message}", e)
        }
    }

    private fun handleTelephonyState(state: Int, incomingNumber: String?) {
        Log.d(TAG, "Telephony state changed in service: state=$state, incomingNumber=$incomingNumber")
        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                AnnouncementManager.acquireWakeLock(applicationContext)
                AnnouncementManager.handleIncomingCall(applicationContext, incomingNumber)
            }
            TelephonyManager.CALL_STATE_OFFHOOK,
            TelephonyManager.CALL_STATE_IDLE -> {
                AnnouncementManager.onCallEnded(applicationContext)
            }
        }
    }

    private fun unregisterTelephonyListener() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                (modernTelephonyCallback as? TelephonyCallback)?.let {
                    telephonyManager?.unregisterTelephonyCallback(it)
                }
                modernTelephonyCallback = null
            } else {
                legacyPhoneStateListener?.let {
                    @Suppress("DEPRECATION")
                    telephonyManager?.listen(it, PhoneStateListener.LISTEN_NONE)
                }
                legacyPhoneStateListener = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering telephony listener: ${e.message}", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "CallAnnounceService onDestroy")
        unregisterTelephonyListener()
        AnnouncementManager.releaseWakeLock()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Smart Call Announce Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }
}
