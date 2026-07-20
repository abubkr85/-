package com.example.head_gesture_app

/**
 * أسماء ملف SharedPreferences الأصلي ومفاتيحه، مشتركة بين MainActivity
 * (للكتابة) وHeadGestureService + GestureAccessibilityService (للقراءة).
 */
object SettingsKeys {
    const val PREFS_NAME = "head_gesture_native_prefs"

    const val DRAG_LENGTH = "drag_length"          // Int (بكسل)
    const val TAP_MODE = "tap_mode"                // "center" | "custom"
    const val TAP_X = "tap_x"                      // Float
    const val TAP_Y = "tap_y"                      // Float
    const val TURN_THRESHOLD = "turn_threshold"    // Float (درجات)
    const val TILT_THRESHOLD = "tilt_threshold"    // Float (درجات)
    const val INVERT_HORIZONTAL = "invert_horizontal" // Boolean
    const val INVERT_VERTICAL = "invert_vertical"     // Boolean
}
