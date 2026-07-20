package com.example.head_gesture_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * تنفذ حركات اللمس/السحب الفعلية على الشاشة عبر dispatchGesture،
 * بدون قراءة محتوى الشاشة إطلاقًا.
 */
class GestureAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "GestureAccessibility"

        @Volatile
        var instance: GestureAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "GestureAccessibilityService متصلة")
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    /** ينفّذ أمرًا واحدًا: "right" | "left" | "up" | "down" | "tap" */
    fun executeCommand(command: String) {
        val metrics = resources.displayMetrics
        val screenWidth = metrics.widthPixels
        val screenHeight = metrics.heightPixels
        val centerX = screenWidth / 2f
        val centerY = screenHeight / 2f

        val prefs = getSharedPreferences(SettingsKeys.PREFS_NAME, Context.MODE_PRIVATE)
        val dragLength = prefs.getInt(SettingsKeys.DRAG_LENGTH, 150).toFloat()

        when (command) {
            "right" -> swipe(centerX - dragLength / 2, centerY, centerX + dragLength / 2, centerY)
            "left" -> swipe(centerX + dragLength / 2, centerY, centerX - dragLength / 2, centerY)
            "up" -> swipe(centerX, centerY + dragLength / 2, centerX, centerY - dragLength / 2)
            "down" -> swipe(centerX, centerY - dragLength / 2, centerX, centerY + dragLength / 2)
            "tap" -> {
                val (x, y) = resolveTapPoint(prefs, centerX, centerY)
                tap(x, y)
            }
            else -> Log.w(TAG, "أمر غير معروف: $command")
        }
    }

    private fun resolveTapPoint(
        prefs: android.content.SharedPreferences,
        centerX: Float,
        centerY: Float
    ): Pair<Float, Float> {
        val mode = prefs.getString(SettingsKeys.TAP_MODE, "center")
        return if (mode == "custom") {
            Pair(prefs.getFloat(SettingsKeys.TAP_X, centerX), prefs.getFloat(SettingsKeys.TAP_Y, centerY))
        } else {
            Pair(centerX, centerY)
        }
    }

    private fun swipe(startX: Float, startY: Float, endX: Float, endY: Float, durationMs: Long = 200) {
        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, durationMs))
            .build()
        dispatchGesture(gesture, null, null)
    }

    private fun tap(x: Float, y: Float, durationMs: Long = 50) {
        val path = Path().apply { moveTo(x, y) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, durationMs))
            .build()
        dispatchGesture(gesture, null, null)
    }
}
