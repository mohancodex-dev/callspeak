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
            val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            Log.d(TAG, "Phone state changed: $state, incoming number: $incomingNumber")
            
            val appContext = context.applicationContext
            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    AnnouncementManager.handleIncomingCall(appContext, incomingNumber)
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK, 
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    Log.d(TAG, "State changed to $state, notifying onCallEnded")
                    AnnouncementManager.onCallEnded(appContext)
                }
            }
        }
    }
}
