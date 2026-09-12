package com.inurum.smartcallannounce

import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.provider.ContactsContract
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }

    private val METHOD_CHANNEL = "com.inurum.smartcallannounce/methods"
    private val EVENT_CHANNEL = "com.inurum.smartcallannounce/events"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        AnnouncementManager.initTts(this)
        checkAndRequestRequiredPermissions()
        if (SettingsHelper.isAnnouncementEnabled(this)) {
            startAnnouncerService()
        }
    }

    private fun checkAndRequestRequiredPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val permissions = mutableListOf<String>()
            if (checkSelfPermission(android.Manifest.permission.READ_PHONE_STATE) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                permissions.add(android.Manifest.permission.READ_PHONE_STATE)
            }
            if (checkSelfPermission(android.Manifest.permission.READ_CALL_LOG) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                permissions.add(android.Manifest.permission.READ_CALL_LOG)
            }
            if (checkSelfPermission(android.Manifest.permission.READ_CONTACTS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                permissions.add(android.Manifest.permission.READ_CONTACTS)
            }
            if (permissions.isNotEmpty()) {
                requestPermissions(permissions.toTypedArray(), 1001)
            }
        }
    }

    private fun areRequiredPermissionsGranted(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val phone = checkSelfPermission(android.Manifest.permission.READ_PHONE_STATE) == android.content.pm.PackageManager.PERMISSION_GRANTED
            val callLog = checkSelfPermission(android.Manifest.permission.READ_CALL_LOG) == android.content.pm.PackageManager.PERMISSION_GRANTED
            val contacts = checkSelfPermission(android.Manifest.permission.READ_CONTACTS) == android.content.pm.PackageManager.PERMISSION_GRANTED
            return phone && callLog && contacts
        }
        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1001) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED }
            Log.d(TAG, "Native permissions request completed. All granted: $allGranted")
            if (SettingsHelper.isAnnouncementEnabled(this)) {
                startAnnouncerService()
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "testAnnouncement" -> {
                    AnnouncementManager.testAnnouncement(context)
                    result.success(true)
                }
                "getBluetoothStatus" -> {
                    result.success(isBluetoothAudioConnected())
                }
                "startService" -> {
                    startAnnouncerService()
                    result.success(true)
                }
                "stopService" -> {
                    stopAnnouncerService()
                    result.success(true)
                }
                "requestPermissions" -> {
                    checkAndRequestRequiredPermissions()
                    result.success(true)
                }
                "arePermissionsGranted" -> {
                    result.success(areRequiredPermissionsGranted())
                }
                "getContacts" -> {
                    val contacts = getDeviceContacts()
                    result.success(contacts)
                }
                "previewAnnouncement" -> {
                    val text = call.argument<String>("text") ?: "Test Call"
                    val language = call.argument<String>("language") ?: "en-US"
                    val speechRate = (call.argument<Double>("speechRate") ?: 1.0).toFloat()
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    val repeatMode = call.argument<String>("repeatMode") ?: "three_times"
                    AnnouncementManager.previewAnnouncement(context, text, language, speechRate, volume, repeatMode)
                    result.success(true)
                }
                "stopAnnouncement" -> {
                    AnnouncementManager.stopAnnouncement()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Could listen to Bluetooth/Call events and send to Flutter here
                    // Since the background requirement is primary, this is a placeholder
                    // to satisfy the EventChannel requirement cleanly.
                }

                override fun onCancel(arguments: Any?) {
                    
                }
            }
        )
    }

    private fun isBluetoothAudioConnected(): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false

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
            val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
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

    private fun startAnnouncerService() {
        val serviceIntent = android.content.Intent(this, CallAnnounceService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopAnnouncerService() {
        val serviceIntent = android.content.Intent(this, CallAnnounceService::class.java)
        serviceIntent.action = "STOP_SERVICE"
        startService(serviceIntent)
    }

    private fun getDeviceContacts(): List<Map<String, String>> {
        val contactList = mutableListOf<Map<String, String>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(android.Manifest.permission.READ_CONTACTS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            return contactList
        }

        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone._ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )

        try {
            contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                projection,
                null,
                null,
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} ASC"
            )?.use { cursor ->
                val idCol = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone._ID)
                val nameCol = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val numCol = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

                val seenNumbers = mutableSetOf<String>()
                while (cursor.moveToNext() && contactList.size < 500) {
                    val id = if (idCol >= 0) cursor.getString(idCol) ?: "" else ""
                    val name = if (nameCol >= 0) cursor.getString(nameCol) ?: "Unknown" else "Unknown"
                    val number = if (numCol >= 0) cursor.getString(numCol) ?: "" else ""

                    val norm = number.filter { it.isDigit() }
                    if (norm.length >= 7 && seenNumbers.add(norm)) {
                        contactList.add(
                            mapOf(
                                "id" to id,
                                "name" to name,
                                "number" to number
                            )
                        )
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error loading contacts: ${e.message}")
        }
        return contactList
    }
}
