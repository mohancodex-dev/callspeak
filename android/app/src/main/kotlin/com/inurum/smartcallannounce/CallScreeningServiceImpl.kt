package com.inurum.smartcallannounce

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.Q)
class CallScreeningServiceImpl : CallScreeningService() {
    companion object {
        private const val TAG = "CallScreeningService"
    }

    override fun onScreenCall(details: Call.Details) {
        if (details.callDirection == Call.Details.DIRECTION_INCOMING) {
            val phoneNumber = details.handle?.schemeSpecificPart
            Log.d(TAG, "CallScreeningService received incoming number: $phoneNumber")

            // Allow the call to ring normally
            val response = CallResponse.Builder()
                .setDisallowCall(false)
                .setRejectCall(false)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build()
            respondToCall(details, response)

            if (!phoneNumber.isNullOrBlank()) {
                AnnouncementManager.handleIncomingCall(applicationContext, phoneNumber)
            }
        }
    }
}
