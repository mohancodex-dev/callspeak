package com.inurum.smartcallannounce

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.speech.tts.TextToSpeech
import android.util.Log
import java.util.Locale

object AnnouncementManager {
    private const val TAG = "AnnouncementManager"
    private var tts: TextToSpeech? = null
    private var isSpeaking = false

    fun handleIncomingCall(context: Context, phoneNumber: String?) {
        if (!SettingsHelper.isAnnouncementEnabled(context)) {
            Log.d(TAG, "Smart Call Announce is disabled")
            return
        }

        if (SettingsHelper.isBluetoothOnly(context) && !isBluetoothAudioConnected(context)) {
            Log.d(TAG, "Bluetooth only is ON, but no BT audio device connected")
            return
        }

        val callerName = getCallerName(context, phoneNumber)
        val announcementText = if (callerName != null) {
            "Incoming call from $callerName"
        } else {
            "Incoming call from unknown number"
        }

        speak(context, announcementText)
    }

    fun stopAnnouncement() {
        if (tts != null && isSpeaking) {
            tts?.stop()
            isSpeaking = false
            Log.d(TAG, "Announcement stopped")
        }
    }
    
    fun testAnnouncement(context: Context) {
        speak(context, "This is a test announcement from Smart Call Announce", isTest = true)
    }

    private fun speak(context: Context, text: String, isTest: Boolean = false) {
        val languageStr = SettingsHelper.getLanguage(context)
        val speechRate = SettingsHelper.getSpeechRate(context)

        if (tts == null) {
            tts = TextToSpeech(context.applicationContext) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    configureAndSpeak(text, languageStr, speechRate, isTest)
                } else {
                    Log.e(TAG, "TTS Initialization failed")
                }
            }
        } else {
            configureAndSpeak(text, languageStr, speechRate, isTest)
        }
    }

    private fun configureAndSpeak(text: String, languageStr: String, rate: Float, isTest: Boolean = false) {
        tts?.let {
            val locale = Locale.forLanguageTag(languageStr)
            val result = it.setLanguage(locale)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e(TAG, "Language not supported: $languageStr")
                it.setLanguage(Locale.ENGLISH)
            }
            it.setSpeechRate(rate)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val usage = if (isTest) {
                    android.media.AudioAttributes.USAGE_MEDIA
                } else {
                    android.media.AudioAttributes.USAGE_NOTIFICATION_RINGTONE
                }
                val audioAttributes = android.media.AudioAttributes.Builder()
                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                    .setUsage(usage)
                    .build()
                it.setAudioAttributes(audioAttributes)
            }
            
            val finalAnnouncement = if (isTest) text else "$text. $text. $text."
            it.speak(finalAnnouncement, TextToSpeech.QUEUE_FLUSH, null, "Smart Call Announce_announcement")
            isSpeaking = true
        }
    }

    @SuppressLint("Range")
    private fun getCallerName(context: Context, phoneNumber: String?): String? {
        if (phoneNumber.isNullOrEmpty()) return null

        try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
            
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    return cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error looking up contact: ${e.message}")
        }
        return null
    }

    private fun isBluetoothAudioConnected(context: Context): Boolean {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    device.type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                    device.type == AudioDeviceInfo.TYPE_BLE_SPEAKER) {
                    return true
                }
            }
        } else {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val adapter = bluetoothManager.adapter
            if (adapter != null && adapter.isEnabled) {
                val a2dp = adapter.getProfileConnectionState(BluetoothProfile.A2DP) == BluetoothProfile.STATE_CONNECTED
                val headset = adapter.getProfileConnectionState(BluetoothProfile.HEADSET) == BluetoothProfile.STATE_CONNECTED
                return a2dp || headset
            }
        }
        return false
    }
}
