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
    private var handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var announcementRunnable: Runnable? = null
    private var announcementCount = 0
    private const val MAX_ANNOUNCEMENTS = 3
    private const val DELAY_BETWEEN_ANNOUNCEMENTS = 6000L // Approx 6 seconds = 2 rings

    private fun getLocalizedMessage(languageStr: String, name: String): String {
        return when (languageStr) {
            "hi-IN" -> "$name का फोन आ रहा है।"
            "bn-IN" -> "$name ফোন করছেন।"
            "te-IN" -> "$name నుండి కాల్ వస్తోంది."
            "mr-IN" -> "$name यांचा फोन येत आहे."
            "ta-IN" -> "$name அழைக்கிறார்."
            "gu-IN" -> "$name નો ફોન આવી રહ્યો છે."
            "kn-IN" -> "$name ಅವರಿಂದ ಕರೆ ಬರುತ್ತಿದೆ."
            "ml-IN" -> "$name വിളിക്കുന്നു."
            "pa-IN" -> "$name ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।"
            "or-IN" -> "$name ଙ୍କର ଫୋନ୍ ଆସୁଛି।"
            "as-IN" -> "$name ফোন কৰিছে।"
            "ur-IN" -> "$name کی کال آ رہی ہے۔"
            "kok-IN" -> "$name चो फोन येता."
            "ne-IN", "ne-NP" -> "$name को फोन आउँदैछ।"
            "sd-IN" -> "$name جو فون اچي رهيو آهي."
            "rathawi-IN" -> "$name न फोन आ रयो है।"
            else -> "Incoming call from $name."
        }
    }

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
        val nameToAnnounce = callerName ?: "Unknown"
        val languageStr = SettingsHelper.getLanguage(context)
        val announcementText = getLocalizedMessage(languageStr, nameToAnnounce)

        speak(context, announcementText)
    }

    fun stopAnnouncement() {
        announcementRunnable?.let { handler.removeCallbacks(it) }
        announcementRunnable = null
        if (tts != null && isSpeaking) {
            tts?.stop()
            isSpeaking = false
            Log.d(TAG, "Announcement stopped")
        }
    }
    
    fun testAnnouncement(context: Context) {
        if (SettingsHelper.isBluetoothOnly(context) && !isBluetoothAudioConnected(context)) {
            Log.d(TAG, "Bluetooth only is ON, but no BT audio device connected. Test skipped.")
            // Using a handler to show toast on main thread
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                android.widget.Toast.makeText(context, "Bluetooth not connected!", android.widget.Toast.LENGTH_SHORT).show()
            }
            return
        }
        val languageStr = SettingsHelper.getLanguage(context)
        val announcementText = getLocalizedMessage(languageStr, "Test Caller")
        speak(context, announcementText, isTest = true)
    }

    private fun speak(context: Context, text: String, isTest: Boolean = false) {
        val languageStr = SettingsHelper.getLanguage(context)
        val speechRate = SettingsHelper.getSpeechRate(context)

        if (tts == null) {
            tts = TextToSpeech(context.applicationContext) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    configureAndSpeak(context, text, languageStr, speechRate, isTest)
                } else {
                    Log.e(TAG, "TTS Initialization failed")
                }
            }
        } else {
            configureAndSpeak(context, text, languageStr, speechRate, isTest)
        }
    }

    private fun configureAndSpeak(context: Context, text: String, languageStr: String, rate: Float, isTest: Boolean = false) {
        tts?.let {
            val ttsLanguage = if (languageStr == "rathawi-IN") "hi-IN" else languageStr
            val locale = Locale.forLanguageTag(ttsLanguage)
            val result = it.setLanguage(locale)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e(TAG, "Language not supported: $ttsLanguage")
                it.setLanguage(Locale.ENGLISH)
            }
            it.setSpeechRate(rate)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // If "Announce only with Bluetooth" is ON, we must use USAGE_MEDIA to prevent
                // Android from blasting the ringtone stream to both the speaker and the headset.
                val forceBluetoothStream = SettingsHelper.isBluetoothOnly(context) && isBluetoothAudioConnected(context)
                
                val usage = if ((isTest && isBluetoothAudioConnected(context)) || forceBluetoothStream) {
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
            
            if (isTest) {
                it.speak(text, TextToSpeech.QUEUE_FLUSH, null, "Smart Call Announce_announcement")
                isSpeaking = true
            } else {
                announcementCount = 0
                announcementRunnable?.let { r -> handler.removeCallbacks(r) }
                
                announcementRunnable = object : Runnable {
                    override fun run() {
                        if (announcementCount < MAX_ANNOUNCEMENTS) {
                            it.speak(text, TextToSpeech.QUEUE_FLUSH, null, "Smart Call Announce_announcement_$announcementCount")
                            isSpeaking = true
                            announcementCount++
                            if (announcementCount < MAX_ANNOUNCEMENTS) {
                                handler.postDelayed(this, DELAY_BETWEEN_ANNOUNCEMENTS)
                            }
                        }
                    }
                }
                handler.post(announcementRunnable!!)
            }
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
