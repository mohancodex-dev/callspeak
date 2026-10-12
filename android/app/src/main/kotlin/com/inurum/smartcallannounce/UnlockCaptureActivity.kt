package com.inurum.smartcallannounce

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager

class UnlockCaptureActivity : Activity() {
    companion object {
        private const val TAG = "UnlockCaptureActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "UnlockCaptureActivity onCreate - capturing in foreground transparent activity")

        // 1x1 transparent window, non-touchable and non-focusable
        window.setLayout(1, 1)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        val handler = Handler(Looper.getMainLooper())
        val timeout = Runnable {
            if (!isFinishing) {
                Log.w(TAG, "UnlockCaptureActivity safety timeout, finishing")
                finish()
                overridePendingTransition(0, 0)
            }
        }
        handler.postDelayed(timeout, 4000L)

        UnlockCaptureManager.handleUnlockEvent(this) {
            handler.removeCallbacks(timeout)
            if (!isFinishing) {
                Log.d(TAG, "UnlockCaptureActivity capture complete, finishing")
                finish()
                overridePendingTransition(0, 0)
            }
        }
    }

    override fun onPause() {
        super.onPause()
        overridePendingTransition(0, 0)
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }
}
