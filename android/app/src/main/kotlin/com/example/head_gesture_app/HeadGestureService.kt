package com.example.head_gesture_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * خدمة Foreground تشغّل الكاميرا الأمامية باستمرار عبر CameraX، وتحلّل كل
 * إطار بواسطة ML Kit Face Detection لاستخراج زاوية لف الرأس (يمين/يسار)،
 * زاوية الرفع/الخفض، واحتمالية فتح كل عين (لكشف الغمزة).
 *
 * تستخدم LifecycleService لأن CameraX تحتاج LifecycleOwner لربط الكاميرا،
 * والخدمات العادية لا توفر ذلك تلقائيًا.
 */
class HeadGestureService : LifecycleService() {

    companion object {
        private const val TAG = "HeadGestureService"
        private const val CHANNEL_ID = "head_gesture_channel"
        private const val NOTIFICATION_ID = 43

        // أقل فترة بين تنفيذ أمر والتالي، لمنع تكرار غير مقصود
        private const val COOLDOWN_MS = 900L

        // احتمالية أقل من هذا = العين مغلقة، أعلى من هذا = العين مفتوحة
        private const val EYE_CLOSED_THRESHOLD = 0.35f
        private const val EYE_OPEN_THRESHOLD = 0.65f
    }

    private lateinit var cameraExecutor: ExecutorService
    private var cameraProvider: ProcessCameraProvider? = null
    private var faceDetector: FaceDetector? = null

    private var lastTriggerTime = 0L
    private var turnThreshold = 20f
    private var tiltThreshold = 15f
    private var invertHorizontal = false
    private var invertVertical = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        cameraExecutor = Executors.newSingleThreadExecutor()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        startForeground(NOTIFICATION_ID, buildNotification())
        loadSettings()
        startCamera()
        return START_STICKY
    }

    override fun onDestroy() {
        cameraProvider?.unbindAll()
        faceDetector?.close()
        cameraExecutor.shutdown()
        super.onDestroy()
    }

    private fun loadSettings() {
        val prefs = getSharedPreferences(SettingsKeys.PREFS_NAME, Context.MODE_PRIVATE)
        turnThreshold = prefs.getFloat(SettingsKeys.TURN_THRESHOLD, 20f)
        tiltThreshold = prefs.getFloat(SettingsKeys.TILT_THRESHOLD, 15f)
        invertHorizontal = prefs.getBoolean(SettingsKeys.INVERT_HORIZONTAL, false)
        invertVertical = prefs.getBoolean(SettingsKeys.INVERT_VERTICAL, false)
    }

    private fun startCamera() {
        val options = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL) // مطلوب لاحتمالية فتح العين
            .build()
        faceDetector = FaceDetection.getClient(options)

        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindAnalysis()
            } catch (e: Exception) {
                Log.e(TAG, "فشل تجهيز الكاميرا", e)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun bindAnalysis() {
        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()

        analysis.setAnalyzer(cameraExecutor) { imageProxy ->
            processImage(imageProxy)
        }

        val selector = CameraSelector.DEFAULT_FRONT_CAMERA

        try {
            cameraProvider?.unbindAll()
            // نستخدم هذه الخدمة نفسها كـ LifecycleOwner (LifecycleService)
            cameraProvider?.bindToLifecycle(this, selector, analysis)
        } catch (e: Exception) {
            Log.e(TAG, "فشل ربط تحليل الصورة بالكاميرا", e)
        }
    }

    @ExperimentalGetImage
    private fun processImage(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        val detector = faceDetector
        if (mediaImage == null || detector == null) {
            imageProxy.close()
            return
        }
        val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
        detector.process(image)
            .addOnSuccessListener { faces ->
                if (faces.isNotEmpty()) analyzeFace(faces[0])
            }
            .addOnFailureListener { e -> Log.w(TAG, "فشل تحليل الوجه", e) }
            .addOnCompleteListener { imageProxy.close() }
    }

    private fun analyzeFace(face: Face) {
        val now = System.currentTimeMillis()
        if (now - lastTriggerTime < COOLDOWN_MS) return

        // headEulerAngleY: لف الرأس يمين/يسار (yaw)
        // headEulerAngleX: رفع/خفض الرأس (pitch)
        var yaw = face.headEulerAngleY
        var pitch = face.headEulerAngleX
        if (invertHorizontal) yaw = -yaw
        if (invertVertical) pitch = -pitch

        val leftEyeOpen = face.leftEyeOpenProbability ?: 1f
        val rightEyeOpen = face.rightEyeOpenProbability ?: 1f

        val command: String? = when {
            yaw > turnThreshold -> "left"
            yaw < -turnThreshold -> "right"
            pitch > tiltThreshold -> "up"
            pitch < -tiltThreshold -> "down"
            (leftEyeOpen < EYE_CLOSED_THRESHOLD && rightEyeOpen > EYE_OPEN_THRESHOLD) ||
                (rightEyeOpen < EYE_CLOSED_THRESHOLD && leftEyeOpen > EYE_OPEN_THRESHOLD) -> "tap"
            else -> null
        }

        command?.let {
            lastTriggerTime = now
            Log.i(TAG, "تنفيذ الأمر: $it")
            GestureAccessibilityService.instance?.executeCommand(it)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "التحكم بإيماءات الرأس",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "إشعار يبقى ظاهرًا أثناء مراقبة التطبيق لإيماءات الرأس"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("التحكم بإيماءات الرأس يعمل")
            .setContentText("يراقب: لف الرأس، الرفع/الخفض، وغمزة العين")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
            .build()
    }
}
