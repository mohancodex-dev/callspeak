package com.inurum.smartcallannounce

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.hardware.camera2.params.OutputConfiguration
import android.hardware.camera2.params.SessionConfiguration
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

object UnlockCaptureManager {
    private const val TAG = "UnlockCaptureManager"
    const val NOTIFICATION_CHANNEL_ID = "unlock_security_channel"
    private const val NOTIFICATION_ID = 2002
    const val ACTION_TRIGGER_UNLOCK_CAPTURE = "com.inurum.smartcallannounce.TRIGGER_UNLOCK_CAPTURE"

    private const val PREFS_KEY_ENABLED = "flutter.unlock_capture_enabled"
    private const val PREFS_KEY_HISTORY = "flutter.unlock_history_json"
    private const val DEBOUNCE_MILLIS = 6000L

    private var lastUnlockTimestamp: Long = 0L

    var eventSink: EventChannel.EventSink? = null

    fun setFeatureSettings(context: Context, enabled: Boolean, showNotification: Boolean) {
        val flutterPrefs = SettingsHelper.getPrefs(context)
        flutterPrefs.edit()
            .putBoolean("flutter.unlock_capture_enabled", enabled)
            .putBoolean("unlock_capture_enabled", enabled)
            .putBoolean("flutter.unlock_show_notification", showNotification)
            .putBoolean("unlock_show_notification", showNotification)
            .apply()

        val defaultPrefs = context.getSharedPreferences(context.packageName + "_preferences", Context.MODE_PRIVATE)
        defaultPrefs.edit()
            .putBoolean("flutter.unlock_capture_enabled", enabled)
            .putBoolean("unlock_capture_enabled", enabled)
            .putBoolean("flutter.unlock_show_notification", showNotification)
            .putBoolean("unlock_show_notification", showNotification)
            .apply()

        Log.d(TAG, "Unlock capture settings synced to native: enabled=$enabled, showNotification=$showNotification")
    }

    fun isFeatureEnabled(context: Context): Boolean {
        val flutterPrefs = SettingsHelper.getPrefs(context)
        if (flutterPrefs.getBoolean("flutter.unlock_capture_enabled", false) ||
            flutterPrefs.getBoolean("unlock_capture_enabled", false)) {
            return true
        }

        val defaultPrefs = context.getSharedPreferences(context.packageName + "_preferences", Context.MODE_PRIVATE)
        return defaultPrefs.getBoolean("flutter.unlock_capture_enabled", false) ||
                defaultPrefs.getBoolean("unlock_capture_enabled", false)
    }

    fun shouldShowNotification(context: Context): Boolean {
        val flutterPrefs = SettingsHelper.getPrefs(context)
        if (flutterPrefs.contains("flutter.unlock_show_notification")) {
            return flutterPrefs.getBoolean("flutter.unlock_show_notification", true)
        }
        if (flutterPrefs.contains("unlock_show_notification")) {
            return flutterPrefs.getBoolean("unlock_show_notification", true)
        }
        val defaultPrefs = context.getSharedPreferences(context.packageName + "_preferences", Context.MODE_PRIVATE)
        return defaultPrefs.getBoolean("unlock_show_notification", true)
    }

    fun isAppInForeground(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return false
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val packageName = context.packageName
        for (appProcess in appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                appProcess.processName == packageName) {
                return true
            }
        }
        return false
    }

    fun handleUnlockEvent(context: Context, onComplete: (() -> Unit)? = null) {
        val now = System.currentTimeMillis()
        if (now - lastUnlockTimestamp < DEBOUNCE_MILLIS) {
            Log.d(TAG, "Ignoring duplicate unlock event within debounce window (${now - lastUnlockTimestamp}ms)")
            onComplete?.invoke()
            return
        }
        lastUnlockTimestamp = now

        if (!isFeatureEnabled(context)) {
            Log.d(TAG, "Unlock capture feature is disabled in settings. Skipping.")
            onComplete?.invoke()
            return
        }

        // Check camera permission
        val hasCameraPermission = ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.CAMERA
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED

        if (!hasCameraPermission) {
            Log.w(TAG, "Camera permission not granted on unlock.")
            logUnlockRecord(
                context = context,
                status = "permission_denied",
                photoPath = null,
                errorMessage = "Camera permission not granted. Please enable camera permission in app settings."
            )
            if (shouldShowNotification(context)) {
                showUnlockNotification(
                    context = context,
                    title = "Device Unlocked - Action Required",
                    message = "Camera permission is required to capture unlock photo. Tap to grant permission.",
                    needsCapture = false
                )
            }
            onComplete?.invoke()
            return
        }

        val inForeground = isAppInForeground(context)
        Log.d(TAG, "Device unlocked. App in foreground: $inForeground. Attempting front camera capture...")

        captureFrontCamera(context) { success, photoPath, errorMsg ->
            try {
                if (success && photoPath != null) {
                    Log.d(TAG, "Unlock photo successfully captured: $photoPath")
                    logUnlockRecord(
                        context = context,
                        status = "captured",
                        photoPath = photoPath,
                        errorMessage = null
                    )
                    if (shouldShowNotification(context)) {
                        showUnlockNotification(
                            context = context,
                            title = "Device Unlocked: Photo Captured",
                            message = "Intruder security photo captured successfully.",
                            needsCapture = false
                        )
                    }
                } else {
                    Log.w(TAG, "Front camera capture failed on unlock: $errorMsg")
                    // Android 9+ background camera restriction or device limitation
                    val isBackgroundRestriction = errorMsg?.contains("restricted", ignoreCase = true) == true ||
                            errorMsg?.contains("disabled", ignoreCase = true) == true ||
                            errorMsg?.contains("access", ignoreCase = true) == true ||
                            errorMsg?.contains("timed out", ignoreCase = true) == true ||
                            !inForeground

                    val status = if (isBackgroundRestriction) "camera_restricted" else "error"
                    val displayError = if (isBackgroundRestriction) {
                        "Android OS restricted background camera access for privacy. Tap notification to verify."
                    } else {
                        errorMsg ?: "Unknown camera capture error."
                    }

                    logUnlockRecord(
                        context = context,
                        status = status,
                        photoPath = null,
                        errorMessage = displayError
                    )

                    // Show fallback notification so user can tap and capture immediately in foreground
                    if (shouldShowNotification(context)) {
                        showUnlockNotification(
                            context = context,
                            title = "Device Unlocked: Security Alert",
                            message = "Unlock detected. Tap here to capture front camera photo and verify.",
                            needsCapture = true
                        )
                    }
                }
            } finally {
                onComplete?.invoke()
            }
        }
    }

    fun captureFrontCamera(
        context: Context,
        callback: (success: Boolean, photoPath: String?, error: String?) -> Unit
    ) {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        if (cameraManager == null) {
            callback(false, null, "CameraManager service not available")
            return
        }

        var frontCameraId: String? = null
        try {
            for (id in cameraManager.cameraIdList) {
                val characteristics = cameraManager.getCameraCharacteristics(id)
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    frontCameraId = id
                    break
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying camera characteristics: ${e.message}")
            callback(false, null, "Failed to inspect cameras: ${e.message}")
            return
        }

        if (frontCameraId == null) {
            // Fallback to back camera if no front camera exists on device
            frontCameraId = cameraManager.cameraIdList.firstOrNull()
        }

        if (frontCameraId == null) {
            callback(false, null, "No camera found on this device")
            return
        }

        val handlerThread = HandlerThread("UnlockCameraCaptureThread")
        handlerThread.start()
        val backgroundHandler = Handler(handlerThread.looper)

        val imageReader = ImageReader.newInstance(640, 480, ImageFormat.JPEG, 2)
        var cameraDevice: CameraDevice? = null
        var isCaptured = false
        val mainHandler = Handler(Looper.getMainLooper())

        fun cleanup() {
            try {
                cameraDevice?.close()
                cameraDevice = null
                imageReader.close()
                handlerThread.quitSafely()
            } catch (e: Exception) {
                Log.e(TAG, "Error cleaning up camera resources: ${e.message}")
            }
        }

        // Safety watchdog timer (5 seconds) to avoid hanging camera hardware
        val watchdog = Runnable {
            if (!isCaptured) {
                Log.w(TAG, "Camera capture timed out. Closing camera.")
                cleanup()
                mainHandler.post {
                    callback(false, null, "Camera capture timed out (restricted by OS or in use)")
                }
            }
        }
        mainHandler.postDelayed(watchdog, 5000L)

        imageReader.setOnImageAvailableListener({ reader ->
            try {
                val image = reader.acquireLatestImage()
                if (image != null) {
                    val buffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)
                    image.close()

                    // Save photo to internal storage
                    val photosDir = File(context.filesDir, "unlock_photos")
                    if (!photosDir.exists()) {
                        photosDir.mkdirs()
                    }
                    val timestamp = System.currentTimeMillis()
                    val photoFile = File(photosDir, "unlock_${timestamp}.jpg")
                    FileOutputStream(photoFile).use { fos ->
                        fos.write(bytes)
                        fos.flush()
                    }

                    isCaptured = true
                    mainHandler.removeCallbacks(watchdog)
                    cleanup()

                    mainHandler.post {
                        callback(true, photoFile.absolutePath, null)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error reading image buffer: ${e.message}")
                mainHandler.removeCallbacks(watchdog)
                cleanup()
                mainHandler.post {
                    callback(false, null, "Failed to save image: ${e.message}")
                }
            }
        }, backgroundHandler)

        try {
            cameraManager.openCamera(frontCameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    try {
                        val captureBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE).apply {
                            addTarget(imageReader.surface)
                            set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
                        }

                        val surfaces = listOf(imageReader.surface)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            val sessionConfig = SessionConfiguration(
                                SessionConfiguration.SESSION_REGULAR,
                                surfaces.map { OutputConfiguration(it) },
                                context.mainExecutor,
                                object : CameraCaptureSession.StateCallback() {
                                    override fun onConfigured(session: CameraCaptureSession) {
                                        try {
                                            session.capture(captureBuilder.build(), null, backgroundHandler)
                                        } catch (e: Exception) {
                                            Log.e(TAG, "Capture request failed: ${e.message}")
                                            mainHandler.removeCallbacks(watchdog)
                                            cleanup()
                                            mainHandler.post {
                                                callback(false, null, "Capture failed: ${e.message}")
                                            }
                                        }
                                    }

                                    override fun onConfigureFailed(session: CameraCaptureSession) {
                                        Log.e(TAG, "Capture session configuration failed")
                                        mainHandler.removeCallbacks(watchdog)
                                        cleanup()
                                        mainHandler.post {
                                            callback(false, null, "Session configuration failed")
                                        }
                                    }
                                }
                            )
                            camera.createCaptureSession(sessionConfig)
                        } else {
                            @Suppress("DEPRECATION")
                            camera.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                                override fun onConfigured(session: CameraCaptureSession) {
                                    try {
                                        session.capture(captureBuilder.build(), null, backgroundHandler)
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Capture request failed: ${e.message}")
                                        mainHandler.removeCallbacks(watchdog)
                                        cleanup()
                                        mainHandler.post {
                                            callback(false, null, "Capture failed: ${e.message}")
                                        }
                                    }
                                }

                                override fun onConfigureFailed(session: CameraCaptureSession) {
                                    Log.e(TAG, "Capture session configuration failed")
                                    mainHandler.removeCallbacks(watchdog)
                                    cleanup()
                                    mainHandler.post {
                                        callback(false, null, "Session configuration failed")
                                    }
                                }
                            }, backgroundHandler)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error configuring camera capture session: ${e.message}")
                        mainHandler.removeCallbacks(watchdog)
                        cleanup()
                        mainHandler.post {
                            callback(false, null, "Session error: ${e.message}")
                        }
                    }
                }

                override fun onDisconnected(camera: CameraDevice) {
                    Log.w(TAG, "Camera device disconnected (likely restricted in background by OS)")
                    mainHandler.removeCallbacks(watchdog)
                    cleanup()
                    mainHandler.post {
                        callback(false, null, "Camera disconnected by Android OS (background camera restriction)")
                    }
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    Log.e(TAG, "Camera device error: $error (restricted by OS or in use)")
                    mainHandler.removeCallbacks(watchdog)
                    cleanup()
                    val errorReason = when (error) {
                        ERROR_CAMERA_DISABLED -> "Camera is disabled by device policy"
                        ERROR_CAMERA_DEVICE -> "Camera device fatal error"
                        ERROR_CAMERA_SERVICE -> "Camera service fatal error"
                        ERROR_CAMERA_IN_USE -> "Camera already in use by another app"
                        ERROR_MAX_CAMERAS_IN_USE -> "Maximum cameras in use"
                        else -> "Camera error code $error"
                    }
                    mainHandler.post {
                        callback(false, null, "Camera access restricted by Android OS: $errorReason")
                    }
                }
            }, backgroundHandler)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException opening camera: ${e.message}")
            mainHandler.removeCallbacks(watchdog)
            cleanup()
            mainHandler.post {
                callback(false, null, "Camera permission or background policy denied: ${e.message}")
            }
        } catch (e: CameraAccessException) {
            Log.e(TAG, "CameraAccessException opening camera: ${e.message}")
            mainHandler.removeCallbacks(watchdog)
            cleanup()
            mainHandler.post {
                callback(false, null, "Camera access restricted: ${e.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error opening camera: ${e.message}")
            mainHandler.removeCallbacks(watchdog)
            cleanup()
            mainHandler.post {
                callback(false, null, "Unexpected camera error: ${e.message}")
            }
        }
    }

    fun logUnlockRecord(
        context: Context,
        status: String,
        photoPath: String?,
        errorMessage: String?
    ) {
        try {
            val prefs = SettingsHelper.getPrefs(context)
            val currentJson = prefs.getString(PREFS_KEY_HISTORY, "[]") ?: "[]"
            val array = JSONArray(currentJson)

            val record = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("timestamp", System.currentTimeMillis())
                put("status", status)
                put("photoPath", photoPath ?: "")
                put("errorMessage", errorMessage ?: "")
            }

            // Create new array with this record first
            val newArray = JSONArray()
            newArray.put(record)
            // Limit to 100 entries to prevent excessive size
            val limit = minOf(array.length(), 99)
            for (i in 0 until limit) {
                newArray.put(array.getJSONObject(i))
            }

            prefs.edit().putString(PREFS_KEY_HISTORY, newArray.toString()).apply()

            // Stream to Flutter if EventChannel is active
            Handler(Looper.getMainLooper()).post {
                try {
                    eventSink?.success(record.toString())
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to emit unlock event to EventSink: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to log unlock record: ${e.message}", e)
        }
    }

    fun getUnlockHistory(context: Context): String {
        val prefs = SettingsHelper.getPrefs(context)
        return prefs.getString(PREFS_KEY_HISTORY, "[]") ?: "[]"
    }

    fun clearUnlockHistory(context: Context): Boolean {
        try {
            // Delete all saved photos
            val photosDir = File(context.filesDir, "unlock_photos")
            if (photosDir.exists() && photosDir.isDirectory) {
                photosDir.listFiles()?.forEach { it.delete() }
            }
            val prefs = SettingsHelper.getPrefs(context)
            prefs.edit().putString(PREFS_KEY_HISTORY, "[]").apply()
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear unlock history: ${e.message}", e)
            return false
        }
    }

    fun deleteUnlockPhoto(context: Context, id: String, photoPath: String?): Boolean {
        try {
            if (!photoPath.isNullOrEmpty()) {
                val file = File(photoPath)
                if (file.exists()) {
                    file.delete()
                }
            }

            val prefs = SettingsHelper.getPrefs(context)
            val currentJson = prefs.getString(PREFS_KEY_HISTORY, "[]") ?: "[]"
            val array = JSONArray(currentJson)
            val newArray = JSONArray()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                if (obj.optString("id") != id) {
                    newArray.put(obj)
                }
            }
            prefs.edit().putString(PREFS_KEY_HISTORY, newArray.toString()).apply()
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete unlock photo: ${e.message}", e)
            return false
        }
    }

    fun showUnlockNotification(
        context: Context,
        title: String,
        message: String,
        needsCapture: Boolean
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        createNotificationChannel(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (needsCapture) {
                putExtra(ACTION_TRIGGER_UNLOCK_CAPTURE, true)
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val iconRes = if (context.applicationInfo.icon != 0) context.applicationInfo.icon else android.R.drawable.ic_menu_camera
        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        try {
            notificationManager.notify(NOTIFICATION_ID, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show unlock notification: ${e.message}")
        }
    }

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Unlock Security Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for device unlock events and camera security alerts"
                enableVibration(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }
    }
}
