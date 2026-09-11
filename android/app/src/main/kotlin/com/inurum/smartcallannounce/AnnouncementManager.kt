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

    private var isPreviewActive = false
    private var currentSessionId: Long = 0L
    private var currentRepeatIndex = 0
    private var targetRepeatCount = 1
    private var pendingNextRepeatRunnable: Runnable? = null
    private var currentAnnouncementText: String? = null
    private var currentSpeechParams: Bundle? = null

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
                                    mainHandler.post {
                                        handleUtteranceDone(utteranceId)
                                    }
                                }

                                override fun onError(utteranceId: String?) {
                                    isSpeaking = false
                                    Log.e(TAG, "TTS utterance error: $utteranceId")
                                    mainHandler.post {
                                        handleUtteranceDone(utteranceId)
                                    }
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

    private fun handleUtteranceDone(utteranceId: String?) {
        if (utteranceId == null || !utteranceId.startsWith("SmartCallAnnounce_${currentSessionId}_")) {
            Log.d(TAG, "Ignoring stale or mismatched utterance callback: $utteranceId for currentSessionId=$currentSessionId")
            return
        }

        if (isSilenced) {
            abandonAudioFocus()
            return
        }

        currentRepeatIndex++
        val canRepeat = (currentCallState == CallState.RINGING || isPreviewActive) && !isSilenced
        val shouldRepeatMore = currentRepeatIndex < targetRepeatCount

        if (canRepeat && shouldRepeatMore) {
            Log.d(TAG, "Scheduling repeat $currentRepeatIndex of $targetRepeatCount in 2500ms")
            val thisSession = currentSessionId
            pendingNextRepeatRunnable?.let { mainHandler.removeCallbacks(it) }
            pendingNextRepeatRunnable = Runnable {
                pendingNextRepeatRunnable = null
                val stillValid = (currentCallState == CallState.RINGING || isPreviewActive) && !isSilenced && (thisSession == currentSessionId)
                val text = currentAnnouncementText
                if (stillValid && text != null && tts != null) {
                    val uid = "SmartCallAnnounce_${thisSession}_$currentRepeatIndex"
                    Log.d(TAG, "Executing repeat utterance $currentRepeatIndex (uid=$uid)")
                    isSpeaking = true
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, currentSpeechParams, uid)
                    } else {
                        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, uid)
                    }
                } else {
                    isSpeaking = false
                    isAnnouncingCall = false
                    isPreviewActive = false
                    abandonAudioFocus()
                }
            }
            mainHandler.postDelayed(pendingNextRepeatRunnable!!, 2500)
        } else {
            Log.d(TAG, "Announcement complete after $currentRepeatIndex repetitions")
            isSpeaking = false
            isAnnouncingCall = false
            isPreviewActive = false
            abandonAudioFocus()
        }
    }

    private fun requestAudioFocus(context: Context): Boolean {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        audioManager = am

        val isBtConnected = isBluetoothAudioConnected(context)
        val alsoSpeaker = SettingsHelper.isAlsoAnnounceOnSpeaker(context)
        val focusUsage = if (isPreviewActive || (isBtConnected && !alsoSpeaker)) {
            AudioAttributes.USAGE_MEDIA
        } else {
            AudioAttributes.USAGE_NOTIFICATION_RINGTONE
        }

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val playbackAttrs = AudioAttributes.Builder()
                    .setUsage(focusUsage)
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
                val streamType = if (isPreviewActive || (isBtConnected && !alsoSpeaker)) AudioManager.STREAM_MUSIC else AudioManager.STREAM_RING
                @Suppress("DEPRECATION")
                am.requestAudioFocus(
                    null,
                    streamType,
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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                try {
                    audioManager?.clearCommunicationDevice()
                } catch (e: Exception) {
                    // ignore
                }
            }
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

    private fun formatPhoneNumberForSpeech(number: String?): String {
        if (number.isNullOrBlank()) return ""
        val sb = StringBuilder()
        for (ch in number) {
            if (ch.isDigit()) {
                sb.append(ch).append(' ')
            } else if (ch == '+') {
                sb.append("+ ")
            }
        }
        return sb.toString().trim()
    }

    private fun getUnknownCallerLabel(languageStr: String): String {
        return when (languageStr) {
            "hi-IN" -> "अज्ञात नंबर"
            "rathawi-IN" -> "अनजान नंबर"
            "bn-IN" -> "অজানা নম্বর"
            "te-IN" -> "తెలియని నంబర్"
            "mr-IN" -> "अनोळखी नंबर"
            "ta-IN" -> "தெரியாத எண்"
            "gu-IN" -> "અજાણ્યો નંબર"
            "kn-IN" -> "ಅಪರಿಚಿತ ಸಂಖ್ಯೆ"
            "ml-IN" -> "അജ്ഞാത നമ്പർ"
            "pa-IN" -> "ਅਣਜਾਣ ਨੰਬਰ"
            "or-IN" -> "ଅଜଣା ନମ୍ବର"
            "as-IN" -> "অচিনাকী নম্বৰ"
            "ur-IN" -> "نامعلوم نمبر"
            "kok-IN" -> "अनोळखी नंबर"
            "ne-IN", "ne-NP" -> "अपरिचित नम्बर"
            "sd-IN" -> "اڻڄাত نمبر"
            else -> "Unknown Number"
        }
    }

    private fun getLocalizedContactMessage(languageStr: String, name: String): String {
        val contactName = if (name.trim().isNotEmpty()) name.trim() else "Someone"
        return when (languageStr) {
            "hi-IN" -> "$contactName का फोन आ रहा है।"
            "rathawi-IN" -> "$contactName ने फोन आय रयो"
            "bn-IN" -> "$contactName ফোন করছেন।"
            "te-IN" -> "$contactName నుండి కాల్ వస్తోంది."
            "mr-IN" -> "$contactName यांचा फोन येत आहे."
            "ta-IN" -> "$contactName அழைக்கிறார்."
            "gu-IN" -> "$contactName નો ફોન આવી રહ્યો છે."
            "kn-IN" -> "$contactName ಅವರಿಂದ ಕರೆ ಬರುತ್ತಿದೆ."
            "ml-IN" -> "$contactName വിളിക്കുന്നു."
            "pa-IN" -> "$contactName ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।"
            "or-IN" -> "$contactName ଙ୍କର ଫୋନ୍ ଆସୁଛି।"
            "as-IN" -> "$contactName ফোন কৰিছে।"
            "ur-IN" -> "$contactName کی کال آ رہی ہے۔"
            "kok-IN" -> "$contactName चो फोन येता."
            "ne-IN", "ne-NP" -> "$contactName को फोन आउँदैछ।"
            "sd-IN" -> "$contactName جو فون اچي رهيو آهي."
            else -> "Incoming call from $contactName."
        }
    }

    private fun getLocalizedUnknownMessage(languageStr: String, phoneNumber: String?): String {
        val target = if (!phoneNumber.isNullOrBlank() && phoneNumber.trim() != "null") {
            formatPhoneNumberForSpeech(phoneNumber)
        } else {
            getUnknownCallerLabel(languageStr)
        }

        return when (languageStr) {
            "hi-IN" -> "$target का फोन आ रहा है।"
            "rathawi-IN" -> "$target ने फोन आय रयो"
            "bn-IN" -> "$target থেকে ফোন আসছে।"
            "te-IN" -> "$target నుండి కాల్ వస్తోంది."
            "mr-IN" -> "$target वरून फोन येत आहे."
            "ta-IN" -> "$target இலிருந்து அழைப்பு வருகிறது."
            "gu-IN" -> "$target નો ફોન આવી રહ્યો છે."
            "kn-IN" -> "$target ಇಂದ ಕರೆ ಬರುತ್ತಿದೆ."
            "ml-IN" -> "$target ൽ നിന്ന് കോൾ വരുന്നു."
            "pa-IN" -> "$target ਦਾ ਫ਼ੋਨ ਆ ਰਿਹਾ ਹੈ।"
            "or-IN" -> "$target ରୁ ଫୋନ୍ ଆସୁଛି।"
            "as-IN" -> "$target ৰ পৰা ফোন আহিছে।"
            "ur-IN" -> "$target سے کال آ رہی ہے۔"
            "kok-IN" -> "$target चो फोन येता."
            "ne-IN", "ne-NP" -> "$target बाट फोन आउँदैछ।"
            "sd-IN" -> "$target مان ڪال اچي رهي آهي."
            else -> "Incoming call from $target."
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
        val isVip: Boolean,
        val isCustomized: Boolean = false
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
                    val isCustomized = if (obj.has("isCustomized")) {
                        obj.optBoolean("isCustomized", false)
                    } else {
                        val ct = obj.optString("customText", "")
                        val ruleId = obj.optString("id", "")
                        ct.isNotEmpty() && ct != "{name} is calling" && !ct.endsWith("is calling") && !ruleId.startsWith("contact_") && !ruleId.startsWith("device_")
                    }

                    return ParsedContactRule(
                        name = obj.optString("name", "Unknown"),
                        phoneNumber = ruleNumber,
                        isEnabled = obj.optBoolean("isEnabled", true),
                        customText = obj.optString("customText", "{name} is calling"),
                        language = obj.optString("language", "en-US"),
                        volume = obj.optDouble("volume", 1.0).toFloat(),
                        speechRate = obj.optDouble("speechRate", 1.0).toFloat(),
                        repeatMode = obj.optString("repeatMode", "three_times").let { if (it == "twice") "three_times" else it },
                        bluetoothOnly = obj.optBoolean("bluetoothOnly", false),
                        isVip = obj.optBoolean("isVip", false),
                        isCustomized = isCustomized
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
                repeatMode = catObj.optString("repeatMode", "three_times").let { if (it == "twice") "three_times" else it },
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
        val globalLanguage = SettingsHelper.getLanguage(context)
        val globalRepeatMode = SettingsHelper.getRepeatMode(context)
        val globalSpeechRate = SettingsHelper.getSpeechRate(context)

        // 1. Check for specific ContactRule
        val contactRule = findContactRule(context, phoneNumber)
        if (contactRule != null) {
            Log.d(TAG, "Found contact rule for ${contactRule.name} (enabled=${contactRule.isEnabled}, isCustomized=${contactRule.isCustomized})")
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

            if (contactRule.isCustomized) {
                // Contact was personalized by user! Apply their custom text and language override.
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
            } else {
                // Not individually customized: dynamically use Home Screen language & repeat mode!
                val text = getLocalizedContactMessage(globalLanguage, nameToAnnounce)
                speak(
                    context = context,
                    text = text,
                    languageStr = globalLanguage,
                    speechRate = contactRule.speechRate,
                    repeatMode = globalRepeatMode,
                    volume = contactRule.volume,
                    isTest = false
                )
            }
            return
        }

        // 2. Check Category Rules & Unknown/Saved Callers
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
            } else {
                if (SettingsHelper.isBluetoothOnly(context) && !isBluetoothAudioConnected(context)) return
                if (SettingsHelper.isSilenceInSilentMode(context) && isSilentOrVibrate(context)) return
                if (SettingsHelper.isSilenceInDndMode(context) && isDndActive(context)) return
            }

            val repeatMode = unknownRule?.repeatMode ?: globalRepeatMode
            val text = getLocalizedUnknownMessage(globalLanguage, phoneNumber)
            speak(
                context = context,
                text = text,
                languageStr = globalLanguage,
                speechRate = globalSpeechRate,
                repeatMode = repeatMode,
                isTest = false
            )
            return
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
            } else {
                if (SettingsHelper.isBluetoothOnly(context) && !isBluetoothAudioConnected(context)) return
                if (SettingsHelper.isSilenceInSilentMode(context) && isSilentOrVibrate(context)) return
                if (SettingsHelper.isSilenceInDndMode(context) && isDndActive(context)) return
            }

            val repeatMode = savedRule?.repeatMode ?: globalRepeatMode
            val text = getLocalizedContactMessage(globalLanguage, nameToAnnounce)
            speak(
                context = context,
                text = text,
                languageStr = globalLanguage,
                speechRate = globalSpeechRate,
                repeatMode = repeatMode,
                isTest = false
            )
            return
        }
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
        currentSessionId = 0L
        isSilenced = true
        isAnnouncingCall = false
        isPreviewActive = false
        currentRepeatIndex = 0

        pendingNextRepeatRunnable?.let {
            mainHandler.removeCallbacks(it)
            pendingNextRepeatRunnable = null
        }
        pendingSilenceStopRunnable?.let {
            mainHandler.removeCallbacks(it)
            pendingSilenceStopRunnable = null
        }
        pendingUnknownAnnouncementRunnable?.let {
            mainHandler.removeCallbacks(it)
            pendingUnknownAnnouncementRunnable = null
        }

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
                        // Ringtone stopped (e.g. user pressed volume or power button to silence ringer).
                        // Note: If announcement is currently speaking or in between repeat intervals,
                        // ringtone ducking is normal and expected — do not false-silence!
                        if (!isSpeaking && pendingNextRepeatRunnable == null) {
                            if (pendingSilenceStopRunnable == null) {
                                pendingSilenceStopRunnable = Runnable {
                                    pendingSilenceStopRunnable = null
                                    if (currentCallState == CallState.RINGING && !isSilenced && !isSpeaking && pendingNextRepeatRunnable == null) {
                                        Log.d(TAG, "System ringtone stopped by user. Silencing announcement.")
                                        stopAnnouncement()
                                    }
                                }
                                mainHandler.postDelayed(pendingSilenceStopRunnable!!, 4000)
                            }
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

        // 2. BroadcastReceiver for hardware volume down and ringer mode changes
        // Detects when the user deliberately presses Volume Down to silence the call.
        // Ascending ringtone (volume increases) is ignored to prevent false mutes.
        silenceReceiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                if (isSilenced) return
                val action = intent?.action ?: return

                if (action == "android.media.VOLUME_CHANGED_ACTION") {
                    // Ignore initial audio stream setup events during first 500ms of the call
                    if (System.currentTimeMillis() - callStartTime < 500) return

                    val streamType = intent.getIntExtra("android.media.EXTRA_VOLUME_STREAM_TYPE", -1)
                    val prevVol = intent.getIntExtra("android.media.EXTRA_PREV_VOLUME_STREAM_VALUE", -1)
                    val newVol = intent.getIntExtra("android.media.EXTRA_VOLUME_STREAM_VALUE", -1)

                    if (streamType == AudioManager.STREAM_RING || streamType == AudioManager.STREAM_NOTIFICATION) {
                        // User pressed Volume Down or muted stream
                        if (newVol < prevVol || newVol == 0) {
                            Log.d(TAG, "User pressed volume down (stream=$streamType, prev=$prevVol, new=$newVol). Silencing announcement.")
                            stopAnnouncement()
                            return
                        }
                    }
                }

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
            addAction("android.media.VOLUME_CHANGED_ACTION")
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
        val languageStr = SettingsHelper.getLanguage(context)
        val repeatMode = SettingsHelper.getRepeatMode(context)
        val rate = SettingsHelper.getSpeechRate(context)
        val announcementText = getLocalizedContactMessage(languageStr, "Test Caller")
        previewAnnouncement(context, announcementText, languageStr, rate, 1.0f, repeatMode)
    }

    fun previewAnnouncement(
        context: Context,
        text: String,
        languageStr: String,
        rate: Float,
        volume: Float,
        repeatMode: String = "three_times"
    ) {
        stopAnnouncement()
        isSilenced = false
        isPreviewActive = true
        speak(
            context = context,
            text = text,
            languageStr = languageStr,
            speechRate = rate,
            repeatMode = repeatMode,
            volume = volume,
            isTest = false
        )
    }

    private fun speak(
        context: Context,
        text: String,
        languageStr: String = "",
        speechRate: Float = -1f,
        repeatMode: String = "three_times",
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
        repeatMode: String = "three_times",
        volume: Float = 1.0f,
        isTest: Boolean = false
    ) {
        if (isSilenced) {
            Log.d(TAG, "Announcement is silenced, cancelling speech")
            return
        }

        // Request audio focus with ducking so speech is clearly audible
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

            val isBtConnected = isBluetoothAudioConnected(context)
            val alsoSpeaker = SettingsHelper.isAlsoAnnounceOnSpeaker(context)

            if (isPreviewActive && !isBtConnected) {
                try {
                    audioManager?.mode = AudioManager.MODE_NORMAL
                    audioManager?.isSpeakerphoneOn = false
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to normalize audio mode: ${e.message}")
                }
            } else if (isBtConnected && !alsoSpeaker) {
                try {
                    audioManager?.isSpeakerphoneOn = false
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to disable speakerphone: ${e.message}")
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    try {
                        val targetDevice = audioManager?.availableCommunicationDevices?.firstOrNull {
                            it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                            it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                            it.type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                            it.type == AudioDeviceInfo.TYPE_BLE_SPEAKER ||
                            it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                            it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                            it.type == AudioDeviceInfo.TYPE_USB_HEADSET
                        }
                        if (targetDevice != null) {
                            audioManager?.setCommunicationDevice(targetDevice)
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to set communication device: ${e.message}")
                    }
                }
            }

            val usage = if (isPreviewActive || (isBtConnected && !alsoSpeaker)) {
                AudioAttributes.USAGE_MEDIA
            } else {
                AudioAttributes.USAGE_NOTIFICATION_RINGTONE
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .setUsage(usage)
                    .build()
                it.setAudioAttributes(audioAttributes)
            }

            val streamType = if (isPreviewActive || (isBtConnected && !alsoSpeaker)) {
                AudioManager.STREAM_MUSIC
            } else {
                AudioManager.STREAM_RING
            }

            val params = Bundle().apply {
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume.coerceIn(0f, 1f))
                putString(TextToSpeech.Engine.KEY_PARAM_STREAM, streamType.toString())
            }

            val times = when (repeatMode) {
                "once", "1" -> 1
                "two_times", "2" -> 2
                "three_times", "thrice", "3_times", "3", "twice" -> 3
                "until_answered", "continuous" -> if (isPreviewActive) 3 else Int.MAX_VALUE
                else -> 3
            }
            currentSessionId = System.currentTimeMillis()
            val thisSessionId = currentSessionId
            currentRepeatIndex = 0
            targetRepeatCount = times
            currentAnnouncementText = text
            currentSpeechParams = params

            isSpeaking = true
            val uid = "SmartCallAnnounce_${thisSessionId}_0"
            Log.d(TAG, "Calling tts.speak (session=$thisSessionId, text='$text', usage=$usage, stream=$streamType)")
            val speakResult = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                it.speak(text, TextToSpeech.QUEUE_FLUSH, params, uid)
            } else {
                it.speak(text, TextToSpeech.QUEUE_FLUSH, null, uid)
            }
            Log.d(TAG, "tts.speak result: $speakResult")
            if (speakResult != TextToSpeech.SUCCESS) {
                Log.e(TAG, "tts.speak failed with code: $speakResult")
                if (isPreviewActive) {
                    isPreviewActive = false
                    abandonAudioFocus()
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
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false

        // 1. Check AudioDeviceInfo on Android M+ (API 23+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                when (device.type) {
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                    AudioDeviceInfo.TYPE_BLE_HEADSET,
                    AudioDeviceInfo.TYPE_BLE_SPEAKER,
                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                    AudioDeviceInfo.TYPE_USB_HEADSET,
                    AudioDeviceInfo.TYPE_USB_DEVICE,
                    AudioDeviceInfo.TYPE_HEARING_AID -> return true
                }
            }
        }

        // 2. Fallback to AudioManager legacy flags
        @Suppress("DEPRECATION")
        if (audioManager.isBluetoothA2dpOn || audioManager.isBluetoothScoOn || audioManager.isWiredHeadsetOn) {
            return true
        }

        // 3. Fallback to BluetoothAdapter profile connection states
        try {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = bluetoothManager?.adapter
            if (adapter != null && adapter.isEnabled) {
                val a2dp = adapter.getProfileConnectionState(BluetoothProfile.A2DP) == BluetoothProfile.STATE_CONNECTED
                val headset = adapter.getProfileConnectionState(BluetoothProfile.HEADSET) == BluetoothProfile.STATE_CONNECTED
                if (a2dp || headset) return true
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error checking bluetooth adapter state: ${e.message}")
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
