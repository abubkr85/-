package com.example.head_gesture_app

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "head_gesture_app/control"
    private val CAMERA_PERMISSION_REQUEST_CODE = 9002

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCameraPermission" -> {
                    if (isCameraGranted()) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.CAMERA),
                            CAMERA_PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "isCameraPermissionGranted" -> result.success(isCameraGranted())
                "isAccessibilityServiceEnabled" -> result.success(isAccessibilityServiceEnabled())
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "startGestureService" -> {
                    val intent = Intent(this, HeadGestureService::class.java)
                    ContextCompat.startForegroundService(this, intent)
                    result.success(null)
                }
                "stopGestureService" -> {
                    stopService(Intent(this, HeadGestureService::class.java))
                    result.success(null)
                }
                "isServiceRunning" -> result.success(isServiceRunning(HeadGestureService::class.java))
                "updateSettings" -> {
                    val args = call.arguments as Map<*, *>
                    saveSettingsNative(args)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun isCameraGranted(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponent = "$packageName/${GestureAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.split(":").any { it.equals(expectedComponent, ignoreCase = true) }
    }

    @Suppress("DEPRECATION")
    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) return true
        }
        return false
    }

    private fun saveSettingsNative(args: Map<*, *>) {
        val prefs = getSharedPreferences(SettingsKeys.PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putInt(SettingsKeys.DRAG_LENGTH, (args["dragLength"] as? Int) ?: 150)
        editor.putString(SettingsKeys.TAP_MODE, (args["tapPointMode"] as? String) ?: "center")
        (args["tapX"] as? Double)?.let { editor.putFloat(SettingsKeys.TAP_X, it.toFloat()) }
        (args["tapY"] as? Double)?.let { editor.putFloat(SettingsKeys.TAP_Y, it.toFloat()) }
        editor.putFloat(SettingsKeys.TURN_THRESHOLD, ((args["turnThreshold"] as? Double) ?: 20.0).toFloat())
        editor.putFloat(SettingsKeys.TILT_THRESHOLD, ((args["tiltThreshold"] as? Double) ?: 15.0).toFloat())
        editor.putBoolean(SettingsKeys.INVERT_HORIZONTAL, (args["invertHorizontal"] as? Boolean) ?: false)
        editor.putBoolean(SettingsKeys.INVERT_VERTICAL, (args["invertVertical"] as? Boolean) ?: false)
        editor.apply()
    }
}
