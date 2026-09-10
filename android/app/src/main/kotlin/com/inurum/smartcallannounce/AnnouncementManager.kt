package com.inurum.smartcallannounce

import android.annotation.SuppressLint
import android.app.NotificationManager
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.AudioPlaybackConfiguration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.ContactsContract
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

object AnnouncementManager {
    private const val TAG = "AnnouncementManager"
    
    enum class CallState {
        IDLE,
        RINGING,
        OFFHOOK
    }

    private var tts: TextToSpeech? = null
    private var isTtsReady = false
    private var isTtsInitializing = false
    private val pendingTtsCallbacks = mutableListOf<() -> Unit>()

    private var isSpeaking = false
    private var isSilenced = false

    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    var onAnnouncementStoppedListener: (() -> Unit)? = null
    private var silenceReceiver: BroadcastReceiver? = null
    private var playbackCallback: AudioManager.AudioPlaybackCallback? = null
    private var registeredContext: Context? = null
    private var callStartTime = 0L

    private var currentCallState = CallState.IDLE
    private var activeCallNumber: String? = null
    private var isAnnouncingCall = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingUnknownAnnouncementRunnable: Runnable? = null
    private var pendingSilenceStopRunnable: Runnable? = null

    private val contactCache = ConcurrentHashMap<String, String>()

    fun acquireWakeLock(context: Context) {
        try {
            if (wakeLock == null) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "SmartCallAnnounce::CallWakeLock"
                ).apply {
                    setReferenceCounted(false)
                }
            }
            wakeLock?.acquire(45000L) // 45s safety timeout for ringing call
            Log.d(TAG, "WakeLock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring WakeLock: ${e.message}")
        }
    }

    fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d(TAG, "WakeLock released")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock: ${e.message}")
        }
    }

    fun initTts(context: Context, onReady: (() -> Unit)? = null) {
        val appContext = context.applicationContext

        mainHandler.post {
            if (onReady != null) {
                if (isTtsReady && tts != null) {
                    onReady.invoke()
                    return@post
                } else {
                    pendingTtsCallbacks.add(onReady)
                }
            }

            if (isTtsInitializing) {
                Log.d(TAG, "TTS initialization already in progress, callback queued")
                return@post
            }

            isTtsInitializing = true
            Log.d(TAG, "Starting TextToSpeech initialization...")

            try {
                tts = TextToSpeech(appContext) { status ->
                    mainHandler.post {
                        isTtsInitializing = false
                        if (status == TextToSpeech.SUCCESS) {
                            isTtsReady = true
                            Log.d(TAG, "TextToSpeech initialized successfully")

                            // Pre-load user configured language into RAM to eliminate first-call voice model loading delay
                            try {
                                val preferredLang = SettingsHelper.getLanguage(appContext)
                                val ttsLang = if (preferredLang == "rathawi-IN") "hi-IN" else preferredLang
                                tts?.language = Locale.forLanguageTag(ttsLang)
                            } catch (e: Exception) {
                                Log.w(TAG, "Failed to pre-set language in initTts: ${e.message}")
                            }

                            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                                override fun onStart(utteranceId: String?) {
                                    isSpeaking = true
                                    Log.d(TAG, "TTS utterance started: $utteranceId")
                                }

                                override fun onDone(utteranceId: String?) {
                                    isSpeaking = false
                                    Log.d(TAG, "TTS utterance finished: $utteranceId")
                                    if (utteranceId?.contains("final") == true || utteranceId == "SmartCallAnnounce_0") {
                                        abandonAudioFocus()
                                    }
                                }

                                override fun onError(utteranceId: String?) {
                                    isSpeaking = false
                                    abandonAudioFocus()
                                    Log.e(TAG, "TTS utterance error: $utteranceId")
                                }
                            })

                            val callbacks = ArrayList(pendingTtsCallbacks)
                            pendingTtsCallbacks.clear()
                            callbacks.forEach { it.invoke() }
                        } else {
                            isTtsReady = false
                            pendingTtsCallbacks.clear()
                            Log.e(TAG, "TextToSpeech initialization failed with status $status")
                        }
                    }
                }
            } catch (e: Exception) {
                isTtsInitializing = false
                isTtsReady = false
                pendingTtsCallbacks.clear()
                Log.e(TAG, "Exception initializing TextToSpeech: ${e.message}", e)
            }
        }
    }

    private fun requestAudioFocus(context: Context): Boolean {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        audioManager = am
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val playbackAttrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(playbackAttrs)
                    .setAcceptsDelayedFocusGain(false)
                    .setOnAudioFocusChangeListener { /* no-op */ }
                    .build()
                audioFocusRequest = request
                am.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } else {
                @Suppress("DEPRECATION")
                am.requestAudioFocus(
                    null,
                    AudioManager.STREAM_RING,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
                ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting audio focus: ${e.message}")
            false
        }
    }

    private fun abandonAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
                audioFocusRequest = null
            } else {
                @Suppress("DEPRECATION")
                audioManager?.abandonAudioFocus(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error abandoning audio focus: ${e.message}")
        }
    }

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

    data class ParsedContactRule(
        val name: String,
        val phoneNumber: String,
        val isEnabled: Boolean,
        val customText: String,
        val language: String,
        val volume: Float,
        val speechRate: Float,
        val repeatMode: String,
        val bluetoothOnly: Boolean,
        val isVip: Boolean
    )

    data class ParsedCategoryRule(
        val isEnabled: Boolean,
        val template: String,
        val repeatMode: String,
        val bluetoothOnly: Boolean,
        val silentBehavior: String
    )

    private fun findContactRule(context: Context, phoneNumber: String?): ParsedContactRule? {
        if (phoneNumber.isNullOrBlank()) return null
        val jsonStr = SettingsHelper.getContactRulesJson(context) ?: return null
        try {
            val array = JSONArray(jsonStr)
            val digitsIncoming = phoneNumber.filter { it.isDigit() }
            val last10Incoming = if (digitsIncoming.length >= 10) digitsIncoming.takeLast(10) else digitsIncoming

            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val ruleNumber = obj.optString("phoneNumber", "")
                val digitsRule = ruleNumber.filter { it.isDigit() }
                val last10Rule = if (digitsRule.length >= 10) digitsRule.takeLast(10) else digitsRule

                val matches = (digitsIncoming.isNotEmpty() && digitsIncoming == digitsRule) ||
                              (last10Incoming.isNotEmpty() && last10Incoming == last10Rule)

                if (matches) {
                    return ParsedContactRule(
                        name = obj.optString("name", "Unknown"),
                        phoneNumber = ruleNumber,
                        isEnabled = obj.optBoolean("isEnabled", true),
                        customText = obj.optString("customText", "{name} is calling"),
                        language = obj.optString("language", "en-US"),
                        volume = obj.optDouble("volume", 1.0).toFloat(),
                        speechRate = obj.optDouble("speechRate", 1.0).toFloat(),
                        repeatMode = obj.optString("repeatMode", "twice"),
                        bluetoothOnly = obj.optBoolean("bluetoothOnly", false),
                        isVip = obj.optBoolean("isVip", false)
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing contact rules: ${e.message}")
        }
        return null
    }

    private fun getCategoryRule(context: Context, key: String): ParsedCategoryRule? {
        val jsonStr = SettingsHelper.getCategoryRulesJson(context) ?: return null
        try {
            val obj = JSONObject(jsonStr)
            val catObj = obj.optJSONObject(key) ?: return null
            return ParsedCategoryRule(
                isEnabled = catObj.optBoolean("isEnabled", true),
                template = catObj.optString("announcementTemplate", "{name} is calling"),
                repeatMode = catObj.optString("repeatMode", "twice"),
                bluetoothOnly = catObj.optBoolean("bluetoothOnly", false),
                silentBehavior = catObj.optString("silentModeBehavior", "respect_silent")
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing category rules: ${e.message}")
        }
        return null
    }

    fun handleIncomingCall(context: Context, phoneNumber: String?) {
        if (!SettingsHelper.isAnnouncementEnabled(context)) {
            Log.d(TAG, "Smart Call Announce is disabled in settings")
            return
        }

        val appContext = context.applicationContext
        acquireWakeLock(appContext)

        mainHandler.post {
            processIncomingCallOnMainThread(appContext, phoneNumber)
        }
    }

    private fun processIncomingCallOnMainThread(context: Context, incomingPhone: String?) {
        var rawNumber = incomingPhone?.trim()
        if (rawNumber == "null" || rawNumber.isNullOrEmpty()) {
            rawNumber = null
        }

        // If phone number is null/empty, check if CallLog has the incoming call
        if (rawNumber.isNullOrEmpty()) {
            rawNumber = getLastRingingNumberFromCallLog(context)
        }

        Log.d(TAG, "processIncomingCall: state=$currentCallState, rawNumber=$rawNumber, activeCallNumber=$activeCallNumber, isAnnouncing=$isAnnouncingCall")

        // 1. If we are already ringing and currently announcing for this exact phone number, ignore duplicate broadcast
        if (currentCallState == CallState.RINGING && !rawNumber.isNullOrEmpty() && rawNumber == activeCallNumber && isAnnouncingCall) {
            Log.d(TAG, "Already announcing for number $rawNumber, ignoring duplicate broadcast")
            return
        }

        // 2. If we already resolved a valid phone number for the current ringing call, and this new event has null number, ignore it
        if (currentCallState == CallState.RINGING && !activeCallNumber.isNullOrEmpty() && rawNumber.isNullOrEmpty()) {
            Log.d(TAG, "Already have active number $activeCallNumber for current call, ignoring null number broadcast")
            return
        }

        currentCallState = CallState.RINGING

        if (!rawNumber.isNullOrEmpty()) {
            // Concrete phone number available immediately!
            pendingUnknownAnnouncementRunnable?.let {
                mainHandler.removeCallbacks(it)
                pendingUnknownAnnouncementRunnable = null
            }

            activeCallNumber = rawNumber
            startCallAnnouncement(context, rawNumber)
        } else {
            // Phone number is not yet available in this broadcast.
            // Wait up to 800ms for CallScreeningService or subsequent PHONE_STATE broadcast to deliver the number.
            if (pendingUnknownAnnouncementRunnable == null && !isAnnouncingCall) {
                Log.d(TAG, "Number is not yet available. Waiting 800ms for caller ID to resolve before assuming Unknown...")
                pendingUnknownAnnouncementRunnable = Runnable {
                    pendingUnknownAnnouncementRunnable = null
                    if (currentCallState == CallState.RINGING && activeCallNumber.isNullOrEmpty() && !isAnnouncingCall) {
                        Log.d(TAG, "No number received within timeout. Announcing as Unknown Caller.")
                        startCallAnnouncement(context, null)
                    }
                }
                mainHandler.postDelayed(pendingUnknownAnnouncementRunnable!!, 800)
            }
        }
    }

    private fun startCallAnnouncement(context: Context, phoneNumber: String?) {
        isAnnouncingCall = true
        isSilenced = false
        callStartTime = System.currentTimeMillis()
        startSilenceListeners(context)

        val callerName = getCallerName(context, phoneNumber)
        val nameToAnnounce = callerName ?: "Unknown"

        // 1. Check for specific ContactRule
        val contactRule = findContactRule(context, phoneNumber)
        if (contactRule != null) {
            Log.d(TAG, "Found contact rule for ${contactRule.name} (enabled=${contactRule.isEnabled})")
            if (!contactRule.isEnabled) {
                Log.d(TAG, "Announcement muted for contact ${contactRule.name}")
                return
            }

            if (contactRule.bluetoothOnly && !isBluetoothAudioConnected(context)) {
                Log.d(TAG, "Bluetooth only requirement not met for contact ${contactRule.name}")
                return
            }

            if (!contactRule.isVip) {
                if (SettingsHelper.isSilenceInSilentMode(context) && isSilentOrVibrate(context)) {
                    Log.d(TAG, "Phone in Silent/Vibrate mode and contact is not VIP. Skipping.")
                    return
                }
                if (SettingsHelper.isSilenceInDndMode(context) && isDndActive(context)) {
                    Log.d(TAG, "Phone in DND mode and contact is not VIP. Skipping.")
                    return
                }
            }

            val customText = contactRule.customText
                .replace("{name}", nameToAnnounce)
                .replace("{number}", phoneNumber ?: "")
            speak(
                context = context,
                text = customText,
                languageStr = contactRule.language,
                speechRate = contactRule.speechRate,
                repeatMode = contactRule.repeatMode,
                volume = contactRule.volume,
                isTest = false
            )
            return
        }

        // 2. Check Category Rules
        val isUnknownNumber = callerName.isNullOrBlank()
        if (isUnknownNumber) {
            val unknownRule = getCategoryRule(context, "unknownNumbers")
            if (unknownRule != null) {
                if (!unknownRule.isEnabled) {
                    Log.d(TAG, "Unknown numbers announcement is disabled in category rules")
                    return
                }
                if (unknownRule.bluetoothOnly && !isBluetoothAudioConnected(context)) {
                    return
                }
                if (unknownRule.silentBehavior == "respect_silent") {
                    if (SettingsHelper.isSilenceInSilentMode(context) && isSilentOrVibrate(context)) return
                    if (SettingsHelper.isSilenceInDndMode(context) && isDndActive(context)) return
                }
                val text = unknownRule.template
                    .replace("{name}", "Unknown")
                    .replace("{number}", phoneNumber ?: "Unknown")
                speak(
                    context = context,
                    text = text,
                    repeatMode = unknownRule.repeatMode,
                    isTest = false
                )
                return
            }
        } else {
            val savedRule = getCategoryRule(context, "savedContacts")
            if (savedRule != null) {
                if (!savedRule.isEnabled) {
                    Log.d(TAG, "Saved contacts announcement is disabled in category rules")
                    return
                }
                if (savedRule.bluetoothOnly && !isBluetoothAudioConnected(context)) {
                    return
                }
                if (savedRule.silentBehavior == "respect_silent") {
                    if (SettingsHelper.isSilenceInSilentMode(context) && isSilentOrVibrate(context)) return
                    if (SettingsHelper.isSilenceInDndMode(context) && isDndActive(context)) return
                }
                val text = savedRule.template
                    .replace("{name}", nameToAnnounce)
                    .replace("{number}", phoneNumber ?: "")
                speak(
                    context = context,
                    text = text,
                    repeatMode = savedRule.repeatMode,
                    isTest = false
                )
                return
            }
        }

        // 3. Fallback to Global Settings
        if (SettingsHelper.isBluetoothOnly(context) && !isBluetoothAudioConnected(context)) {
            Log.d(TAG, "Bluetooth only is ON, but no BT audio device connected")
            return
        }

        if (SettingsHelper.isSilenceInSilentMode(context) && isSilentOrVibrate(context)) {
            Log.d(TAG, "Phone is in Silent/Vibrate mode and silenceInSilentMode is ON, skipping announcement")
            return
        }

        if (SettingsHelper.isSilenceInDndMode(context) && isDndActive(context)) {
            Log.d(TAG, "Phone is in DND mode and silenceInDndMode is ON, skipping announcement")
            return
        }

        val languageStr = SettingsHelper.getLanguage(context)
        val announcementText = getLocalizedMessage(languageStr, nameToAnnounce)
        speak(context, announcementText, isTest = false)
    }

    fun onCallEnded(context: Context) {
        mainHandler.post {
            Log.d(TAG, "onCallEnded: resetting call state")
            pendingUnknownAnnouncementRunnable?.let {
                mainHandler.removeCallbacks(it)
                pendingUnknownAnnouncementRunnable = null
            }
            pendingSilenceStopRunnable?.let {
                mainHandler.removeCallbacks(it)
                pendingSilenceStopRunnable = null
            }
            currentCallState = CallState.IDLE
            activeCallNumber = null
            isAnnouncingCall = false
            stopAnnouncement()
        }
    }

    fun stopAnnouncement() {
        isSilenced = true
        isAnnouncingCall = false

        // Unconditionally stop TTS to flush all queued utterances immediately
        try {
            tts?.stop()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping TTS: ${e.message}")
        }
        isSpeaking = false
        Log.d(TAG, "Announcement stopped and TTS flushed")

        abandonAudioFocus()
        releaseWakeLock()

        pendingSilenceStopRunnable?.let {
            mainHandler.removeCallbacks(it)
            pendingSilenceStopRunnable = null
        }
        pendingUnknownAnnouncementRunnable?.let {
            mainHandler.removeCallbacks(it)
            pendingUnknownAnnouncementRunnable = null
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
        // Detects when the user silences the incoming call (e.g. presses volume/power button).
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
                            if (attrs.usage == AudioAttributes.USAGE_NOTIFICATION_RINGTONE &&
                                attrs.contentType != AudioAttributes.CONTENT_TYPE_SPEECH) {
                                hasSystemRingtoneNow = true
                                break
                            }
                        }
                    }

                    if (hasSystemRingtoneNow) {
                        wasSystemRingtoneActive = true
                        // Ringtone is active or resumed; cancel any pending silence stop
                        pendingSilenceStopRunnable?.let {
                            mainHandler.removeCallbacks(it)
                            pendingSilenceStopRunnable = null
                        }
                    } else if (wasSystemRingtoneActive) {
                        // Ringtone paused. Debounce for 4500ms to allow slow loop gaps without false stops
                        if (pendingSilenceStopRunnable == null) {
                            pendingSilenceStopRunnable = Runnable {
                                pendingSilenceStopRunnable = null
                                if (currentCallState == CallState.RINGING && !isSilenced) {
                                    Log.d(TAG, "System ringtone stopped for > 4.5s by user. Silencing announcement.")
                                    stopAnnouncement()
                                }
                            }
                            mainHandler.postDelayed(pendingSilenceStopRunnable!!, 4500)
                        }
                    }
                }
            }

            try {
                audioManager.registerAudioPlaybackCallback(
                    playbackCallback!!,
                    mainHandler
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error registering AudioPlaybackCallback", e)
            }
        }

        // 2. BroadcastReceiver for explicit ringer mode changes
        // NOTE: We deliberately do NOT listen to VOLUME_CHANGED_ACTION or ACTION_SCREEN_OFF here!
        // VOLUME_CHANGED_ACTION fires on normal ascending ringtone / stream volume ramping and falsely kills speech.
        // ACTION_SCREEN_OFF fires when phone is placed in pocket or proximity sensor activates.
        silenceReceiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                if (isSilenced) return
                val action = intent?.action ?: return

                if (action == AudioManager.RINGER_MODE_CHANGED_ACTION) {
                    val am = appContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                    val mode = am?.ringerMode
                    if (mode == AudioManager.RINGER_MODE_SILENT || mode == AudioManager.RINGER_MODE_VIBRATE) {
                        if (SettingsHelper.isSilenceInSilentMode(appContext)) {
                            Log.d(TAG, "Ringer mode changed to silent/vibrate by user. Silencing announcement.")
                            stopAnnouncement()
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(AudioManager.RINGER_MODE_CHANGED_ACTION)
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
                val am = ctx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                playbackCallback?.let {
                    try {
                        am?.unregisterAudioPlaybackCallback(it)
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
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(context, "Bluetooth not connected!", Toast.LENGTH_SHORT).show()
            }
            return
        }
        if (SettingsHelper.isSilenceInSilentMode(context) && isSilentOrVibrate(context)) {
            Log.d(TAG, "Phone is in Silent/Vibrate mode. Test skipped.")
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(context, "Phone is in Silent/Vibrate mode!", Toast.LENGTH_SHORT).show()
            }
            return
        }
        if (SettingsHelper.isSilenceInDndMode(context) && isDndActive(context)) {
            Log.d(TAG, "Phone is in DND mode. Test skipped.")
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(context, "Phone is in Do Not Disturb (DND) mode!", Toast.LENGTH_SHORT).show()
            }
            return
        }
        val languageStr = SettingsHelper.getLanguage(context)
        val announcementText = getLocalizedMessage(languageStr, "Test Caller")
        speak(context, announcementText, isTest = true)
    }

    fun previewAnnouncement(context: Context, text: String, languageStr: String, rate: Float, volume: Float) {
        speak(
            context = context,
            text = text,
            languageStr = languageStr,
            speechRate = rate,
            repeatMode = "once",
            volume = volume,
            isTest = true
        )
    }

    private fun speak(
        context: Context,
        text: String,
        languageStr: String = "",
        speechRate: Float = -1f,
        repeatMode: String = "twice",
        volume: Float = 1.0f,
        isTest: Boolean = false
    ) {
        val effectiveLang = if (languageStr.isNotEmpty()) languageStr else SettingsHelper.getLanguage(context)
        val effectiveRate = if (speechRate > 0f) speechRate else SettingsHelper.getSpeechRate(context)

        if (tts == null || !isTtsReady) {
            Log.d(TAG, "TTS not ready, initializing now...")
            initTts(context) {
                configureAndSpeak(context, text, effectiveLang, effectiveRate, repeatMode, volume, isTest)
            }
        } else {
            configureAndSpeak(context, text, effectiveLang, effectiveRate, repeatMode, volume, isTest)
        }
    }

    private fun configureAndSpeak(
        context: Context,
        text: String,
        languageStr: String,
        rate: Float,
        repeatMode: String = "twice",
        volume: Float = 1.0f,
        isTest: Boolean = false
    ) {
        if (isSilenced) {
            Log.d(TAG, "Announcement is silenced, cancelling speech")
            return
        }

        // Request audio focus with ducking so the incoming ringtone lowers in volume while speech is announced
        requestAudioFocus(context)

        tts?.let {
            val ttsLanguage = if (languageStr == "rathawi-IN") "hi-IN" else languageStr
            val locale = Locale.forLanguageTag(ttsLanguage)
            val result = it.setLanguage(locale)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e(TAG, "Language not supported: $ttsLanguage, falling back to English")
                it.setLanguage(Locale.ENGLISH)
            }
            it.setSpeechRate(rate)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val isBtConnected = isBluetoothAudioConnected(context)
                val alsoSpeaker = SettingsHelper.isAlsoAnnounceOnSpeaker(context)

                val usage = if (isBtConnected && !alsoSpeaker) {
                    // Route strictly to Bluetooth headset; internal phone speaker stays silent
                    AudioAttributes.USAGE_VOICE_COMMUNICATION
                } else {
                    // Ringtone stream routes to phone speaker (and also Bluetooth if connected and alsoSpeaker is true)
                    AudioAttributes.USAGE_NOTIFICATION_RINGTONE
                }

                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .setUsage(usage)
                    .build()
                it.setAudioAttributes(audioAttributes)
            }

            val params = Bundle().apply {
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume.coerceIn(0f, 1f))
            }

            isSpeaking = true

            if (isTest || repeatMode == "once") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    it.speak(text, TextToSpeech.QUEUE_FLUSH, params, "SmartCallAnnounce_final_0")
                } else {
                    it.speak(text, TextToSpeech.QUEUE_FLUSH, null, "SmartCallAnnounce_0")
                }
            } else {
                val times = if (repeatMode == "until_answered") 6 else 2
                val finalIndex = times - 1

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    it.speak(text, TextToSpeech.QUEUE_FLUSH, params, "SmartCallAnnounce_0")
                    for (i in 1 until times) {
                        it.playSilentUtterance(3000, TextToSpeech.QUEUE_ADD, "SmartCallAnnounce_silence_$i")
                        val utteranceId = if (i == finalIndex) "SmartCallAnnounce_final_$i" else "SmartCallAnnounce_$i"
                        it.speak(text, TextToSpeech.QUEUE_ADD, params, utteranceId)
                    }
                } else {
                    val repeated = List(times) { text }.joinToString(". ")
                    it.speak(repeated, TextToSpeech.QUEUE_FLUSH, null, "SmartCallAnnounce_old")
                }
            }
        }
    }

    private fun getLastRingingNumberFromCallLog(context: Context): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            context.checkSelfPermission(android.Manifest.permission.READ_CALL_LOG) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            return null
        }
        try {
            val uri = android.provider.CallLog.Calls.CONTENT_URI
            val projection = arrayOf(
                android.provider.CallLog.Calls.NUMBER,
                android.provider.CallLog.Calls.DATE
            )
            val sortOrder = "${android.provider.CallLog.Calls.DATE} DESC"
            context.contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val numIdx = cursor.getColumnIndex(android.provider.CallLog.Calls.NUMBER)
                    val dateIdx = cursor.getColumnIndex(android.provider.CallLog.Calls.DATE)
                    if (numIdx >= 0 && dateIdx >= 0) {
                        val date = cursor.getLong(dateIdx)
                        // If call was logged within the last 4 seconds
                        if (System.currentTimeMillis() - date < 4000) {
                            val num = cursor.getString(numIdx)
                            if (!num.isNullOrBlank()) {
                                Log.d(TAG, "Resolved incoming number from CallLog: $num")
                                return num
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.d(TAG, "Error checking CallLog for incoming number: ${e.message}")
        }
        return null
    }

    @SuppressLint("Range")
    private fun getCallerName(context: Context, phoneNumber: String?): String? {
        if (phoneNumber.isNullOrBlank()) return null
        val trimmedNumber = phoneNumber.trim()

        // Fast memory cache check (0ms latency for repeated calls)
        contactCache[trimmedNumber]?.let { return it }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            context.checkSelfPermission(android.Manifest.permission.READ_CONTACTS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "READ_CONTACTS permission not granted")
            return null
        }

        // Strategy 1: ContactsContract.PhoneLookup with raw number
        try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(trimmedNumber))
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)

            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIdx = cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                    if (nameIdx >= 0) {
                        val name = cursor.getString(nameIdx)
                        if (!name.isNullOrBlank()) {
                            Log.d(TAG, "Contact found via PhoneLookup raw: $name")
                            contactCache[trimmedNumber] = name
                            return name
                        }
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
                        val nameIdx = cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                        if (nameIdx >= 0) {
                            val name = cursor.getString(nameIdx)
                            if (!name.isNullOrBlank()) {
                                Log.d(TAG, "Contact found via PhoneLookup digits: $name")
                                contactCache[trimmedNumber] = name
                                return name
                            }
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
                        val nameIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                        if (nameIdx >= 0) {
                            val name = cursor.getString(nameIdx)
                            if (!name.isNullOrBlank()) {
                                Log.d(TAG, "Contact found via CommonDataKinds.Phone: $name")
                                contactCache[trimmedNumber] = name
                                return name
                            }
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

    fun isSilentOrVibrate(context: Context): Boolean {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        val ringerMode = audioManager.ringerMode
        return ringerMode == AudioManager.RINGER_MODE_SILENT || ringerMode == AudioManager.RINGER_MODE_VIBRATE
    }

    fun isDndActive(context: Context): Boolean {
        // 1. NotificationManager check (Android M / 23+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                if (notificationManager != null) {
                    val filter = notificationManager.currentInterruptionFilter
                    if (filter != NotificationManager.INTERRUPTION_FILTER_ALL &&
                        filter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN) {
                        return true
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking interruption filter: ${e.message}")
            }
        }

        // 2. Fallback to Settings.Global zen_mode
        try {
            val zenMode = Settings.Global.getInt(context.contentResolver, "zen_mode", 0)
            if (zenMode != 0) {
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking zen_mode: ${e.message}")
        }

        return false
    }
}
