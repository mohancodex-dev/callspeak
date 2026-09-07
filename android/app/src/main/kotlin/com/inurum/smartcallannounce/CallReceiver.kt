package com.inurum.smartcallannounce

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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
            
            val pendingResult = goAsync()
            
            var ringingThread: Thread? = null
            ringingThread = Thread {
                AnnouncementManager.onAnnouncementStoppedListener = {
                    try {
                        ringingThread?.interrupt()
                    } catch (e: Exception) {
                        // Ignore
                    }
                }
                try {
                    when (state) {
                        TelephonyManager.EXTRA_STATE_RINGING -> {
                            val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                            Log.d(TAG, "Ringing")
                            AnnouncementManager.handleIncomingCall(context, incomingNumber)
                        }
                        TelephonyManager.EXTRA_STATE_OFFHOOK, 
                        TelephonyManager.EXTRA_STATE_IDLE -> {
                            Log.d(TAG, "State changed to $state, stopping announcement")
                            AnnouncementManager.stopAnnouncement()
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in CallReceiver", e)
                } finally {
                    if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                        try {
                            Thread.sleep(20000)
                        } catch (e: InterruptedException) {
                            Log.d(TAG, "Ringing thread sleep interrupted early")
                        }
                    }
                    AnnouncementManager.onAnnouncementStoppedListener = null
                    pendingResult.finish()
                }
            }
            ringingThread.start()
        }
    }
}
