package com.inurum.smartcallannounce

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.AudioPlaybackConfiguration
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract
import android.speech.tts.TextToSpeech
import android.util.Log
import java.util.Locale

object AnnouncementManager {
    private const val TAG = "AnnouncementManager"
    private var tts: TextToSpeech? = null
    private var isSpeaking = false
    private var isSilenced = false

    var onAnnouncementStoppedListener: (() -> Unit)? = null
    private var silenceReceiver: BroadcastReceiver? = null
    private var playbackCallback: AudioManager.AudioPlaybackCallback? = null
    private var registeredContext: Context? = null
    private var callStartTime = 0L
    private var lastIncomingNumber: String? = null
    private var lastAnnounceTime = 0L

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
            "or-IN" -> "$name ଙ୍କର ଫୋନ୍ ଆସୁଛି。"
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

        val now = System.currentTimeMillis()
        // Deduplication / smart update check
        if (isSpeaking && now - lastAnnounceTime < 4000) {
            if (lastIncomingNumber.isNullOrEmpty() && !phoneNumber.isNullOrEmpty()) {
                Log.d(TAG, "Updating announcement with newly resolved phone number: $phoneNumber")
                stopAnnouncement()
            } else {
                Log.d(TAG, "Already announcing this call, skipping duplicate trigger")
                return
            }
        }

        lastIncomingNumber = phoneNumber
        lastAnnounceTime = now
        isSilenced = false
        callStartTime = now
        startSilenceListeners(context)

        val callerName = getCallerName(context, phoneNumber)
        val nameToAnnounce = callerName ?: "Unknown"
        val languageStr = SettingsHelper.getLanguage(context)
        val announcementText = getLocalizedMessage(languageStr, nameToAnnounce)

        speak(context, announcementText, isTest = false)
    }

    fun stopAnnouncement() {
        isSilenced = true
        if (tts != null && isSpeaking) {
            tts?.stop()
            isSpeaking = false
            Log.d(TAG, "Announcement stopped")
        }
        stopSilenceListeners()
        onAnnouncementStoppedListener?.invoke()
    }

    private fun startSilenceListeners(context: Context) {
        stopSilenceListeners()
        val appContext = context.applicationContext
        registeredContext = appContext
        val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

        // 1. AudioPlaybackCallback (Android 8.0+)
        // When the user presses the volume button or power button during an incoming call,
        // Android OS silences and stops the system ringtone.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && audioManager != null) {
            var wasSystemRingtoneActive = false
            playbackCallback = object : AudioManager.AudioPlaybackCallback() {
                override fun onPlaybackConfigChanged(configs: MutableList<AudioPlaybackConfiguration>?) {
                    super.onPlaybackConfigChanged(configs)
                    if (isSilenced) return

                    var hasSystemRingtoneNow = false
                    if (configs != null) {
                        for (config in configs) {
                            val attrs = config.audioAttributes
                            if (attrs.usage == android.media.AudioAttributes.USAGE_NOTIFICATION_RINGTONE &&
                                attrs.contentType != android.media.AudioAttributes.CONTENT_TYPE_SPEECH) {
                                hasSystemRingtoneNow = true
                                break
                            }
                        }
                    }

                    if (hasSystemRingtoneNow) {
                        wasSystemRingtoneActive = true
                    } else if (wasSystemRingtoneActive) {
                        Log.d(TAG, "System ringtone stopped by user (volume/power button pressed). Silencing announcement.")
                        stopAnnouncement()
                    }
                }
            }

            try {
                audioManager.registerAudioPlaybackCallback(
                    playbackCallback!!,
                    Handler(Looper.getMainLooper())
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error registering AudioPlaybackCallback", e)
            }
        }

        // 2. BroadcastReceiver for hardware volume changes and screen off (power button)
        silenceReceiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                if (isSilenced) return
                // Ignore any initial volume broadcast that may happen during call setup (< 500ms)
                if (System.currentTimeMillis() - callStartTime < 500) return

                val action = intent?.action ?: return
                Log.d(TAG, "Silence event detected: $action")
                stopAnnouncement()
            }
        }

        val filter = IntentFilter().apply {
            addAction("android.media.VOLUME_CHANGED_ACTION")
            addAction(AudioManager.RINGER_MODE_CHANGED_ACTION)
            addAction(Intent.ACTION_SCREEN_OFF)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                appContext.registerReceiver(silenceReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                appContext.registerReceiver(silenceReceiver, filter)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error registering silenceReceiver", e)
        }
    }

    private fun stopSilenceListeners() {
        registeredContext?.let { ctx ->
            silenceReceiver?.let {
                try {
                    ctx.unregisterReceiver(it)
                } catch (e: Exception) {
                    // Ignore if already unregistered
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val audioManager = ctx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                playbackCallback?.let {
                    try {
                        audioManager?.unregisterAudioPlaybackCallback(it)
                    } catch (e: Exception) {
                        // Ignore
                    }
                }
            }
        }
        silenceReceiver = null
        playbackCallback = null
        registeredContext = null
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
        if (isSilenced) {
            Log.d(TAG, "Announcement is silenced, cancelling speech")
            return
        }
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
                val isBtConnected = isBluetoothAudioConnected(context)
                val alsoSpeaker = SettingsHelper.isAlsoAnnounceOnSpeaker(context)

                val usage = if (isBtConnected && !alsoSpeaker) {
                    // Route strictly to Bluetooth headset; internal phone speaker stays silent
                    android.media.AudioAttributes.USAGE_VOICE_COMMUNICATION
                } else {
                    // Ringtone stream routes to phone speaker (and also Bluetooth if connected and alsoSpeaker is true)
                    android.media.AudioAttributes.USAGE_NOTIFICATION_RINGTONE
                }
                
                val audioAttributes = android.media.AudioAttributes.Builder()
                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                    .setUsage(usage)
                    .build()
                it.setAudioAttributes(audioAttributes)
            }
            
            isSpeaking = true
            if (isTest) {
                it.speak(text, TextToSpeech.QUEUE_FLUSH, null, "Smart Call Announce_announcement")
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    it.speak(text, TextToSpeech.QUEUE_FLUSH, null, "Smart Call Announce_announcement_0")
                    it.playSilentUtterance(5000, TextToSpeech.QUEUE_ADD, "Smart Call Announce_silence_1")
                    it.speak(text, TextToSpeech.QUEUE_ADD, null, "Smart Call Announce_announcement_1")
                    it.playSilentUtterance(5000, TextToSpeech.QUEUE_ADD, "Smart Call Announce_silence_2")
                    it.speak(text, TextToSpeech.QUEUE_ADD, null, "Smart Call Announce_announcement_2")
                } else {
                    it.speak("$text. $text. $text.", TextToSpeech.QUEUE_FLUSH, null, "Smart Call Announce_announcement_old")
                }
            }
        }
    }

    @SuppressLint("Range")
    private fun getCallerName(context: Context, phoneNumber: String?): String? {
        if (phoneNumber.isNullOrBlank()) return null

        val trimmedNumber = phoneNumber.trim()

        // Strategy 1: ContactsContract.PhoneLookup with raw number
        try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(trimmedNumber))
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
            
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val name = cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME))
                    if (!name.isNullOrBlank()) {
                        Log.d(TAG, "Contact found via PhoneLookup raw: $name")
                        return name
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error looking up contact via PhoneLookup raw: ${e.message}")
        }

        // Strategy 2: Clean digits (strip spaces, dashes, parentheses)
        val digitsOnly = trimmedNumber.filter { it.isDigit() }
        if (digitsOnly.isNotEmpty() && digitsOnly != trimmedNumber) {
            try {
                val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(digitsOnly))
                val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
                context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val name = cursor.getString(cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME))
                        if (!name.isNullOrBlank()) {
                            Log.d(TAG, "Contact found via PhoneLookup digits: $name")
                            return name
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error looking up contact via PhoneLookup digits: ${e.message}")
            }
        }

        // Strategy 3: Query ContactsContract.CommonDataKinds.Phone with last 10 digits
        // Critical for India and countries where numbers are stored without +91 or with 0 prefix
        try {
            val last10 = if (digitsOnly.length >= 10) digitsOnly.takeLast(10) else digitsOnly
            if (last10.length >= 7) {
                val phoneUri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
                val projection = arrayOf(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val selection = "${ContactsContract.CommonDataKinds.Phone.NUMBER} LIKE ?"
                val selectionArgs = arrayOf("%$last10%")

                context.contentResolver.query(phoneUri, projection, selection, selectionArgs, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val name = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME))
                        if (!name.isNullOrBlank()) {
                            Log.d(TAG, "Contact found via CommonDataKinds.Phone: $name")
                            return name
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error looking up contact via CommonDataKinds.Phone: ${e.message}")
        }

        Log.d(TAG, "No contact name found for number: $phoneNumber")
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
