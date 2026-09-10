package com.inurum.smartcallannounce

import android.content.Context
import android.content.SharedPreferences

object SettingsHelper {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    
    fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun isAnnouncementEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean("flutter.announcementEnabled", false)
    }

    fun isBluetoothOnly(context: Context): Boolean {
        return getPrefs(context).getBoolean("flutter.announceOnlyWithBluetooth", false)
    }

    fun isAlsoAnnounceOnSpeaker(context: Context): Boolean {
        return getPrefs(context).getBoolean("flutter.alsoAnnounceOnSpeaker", false)
    }

    fun isSilenceInSilentMode(context: Context): Boolean {
        return getPrefs(context).getBoolean("flutter.silenceInSilentMode", true)
    }

    fun isSilenceInDndMode(context: Context): Boolean {
        return getPrefs(context).getBoolean("flutter.silenceInDndMode", true)
    }

    fun getLanguage(context: Context): String {
        return getPrefs(context).getString("flutter.language", "en-US") ?: "en-US"
    }

    fun getSpeechRate(context: Context): Float {
        // SharedPreferences stores Dart doubles as Long (if integer value) or Double bits.
        // Actually flutter shared_preferences stores double as Double but Android SharedPreferences doesn't support Double directly. 
        // Flutter stores double as Float or uses a string? 
        // Let's check flutter's android implementation of shared_preferences.
        // Flutter shared_preferences uses Double.doubleToRawLongBits for double.
        // But the new shared_preferences plugin stores double as a Double via a wrapper?
        // Wait, Flutter stores doubles in SharedPreferences as Strings with a specific prefix "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu" if old, or stores as Float.
        // Let's just use Double.fromRawLongBits if it's a Long, or Float if it's a Float.
        // To be safe, let's just store speechRate as String in Flutter and parse it in Kotlin.
        val rateStr = getPrefs(context).getString("flutter.speechRateStr", "1.0")
        return rateStr?.toFloatOrNull() ?: 1.0f
    }

    fun getContactRulesJson(context: Context): String? {
        return getPrefs(context).getString("flutter.contact_rules_json", null)
    }

    fun getCategoryRulesJson(context: Context): String? {
        return getPrefs(context).getString("flutter.category_rules_json", null)
    }

    fun getSmartFeaturesJson(context: Context): String? {
        return getPrefs(context).getString("flutter.smart_features_json", null)
    }

    fun getRepeatMode(context: Context): String {
        val mode = getPrefs(context).getString("flutter.repeatMode", "three_times") ?: "three_times"
        return if (mode == "twice") "three_times" else mode
    }
}
