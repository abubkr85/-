import 'package:flutter/services.dart';

/// جسر الاتصال بين واجهة Flutter والكود الأصلي (Kotlin).
/// التنفيذ الفعلي (الكاميرا + تحليل الوجه + اللمس/السحب) يحدث في Kotlin.
class NativeBridge {
  NativeBridge._();
  static const MethodChannel _channel =
      MethodChannel('head_gesture_app/control');

  static Future<bool> requestCameraPermission() async {
    final granted =
        await _channel.invokeMethod<bool>('requestCameraPermission');
    return granted ?? false;
  }

  static Future<bool> isCameraPermissionGranted() async {
    final granted =
        await _channel.invokeMethod<bool>('isCameraPermissionGranted');
    return granted ?? false;
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    final enabled =
        await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
    return enabled ?? false;
  }

  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<void> startGestureService() async {
    await _channel.invokeMethod('startGestureService');
  }

  static Future<void> stopGestureService() async {
    await _channel.invokeMethod('stopGestureService');
  }

  static Future<bool> isServiceRunning() async {
    final running = await _channel.invokeMethod<bool>('isServiceRunning');
    return running ?? false;
  }

  /// يرسل إعدادات الحساسية والمعايرة والتنفيذ إلى الكود الأصلي
  static Future<void> updateSettings({
    required int dragLength,
    required String tapPointMode,
    double? tapX,
    double? tapY,
    required double turnThreshold, // درجة لف الرأس يمين/يسار
    required double tiltThreshold, // درجة رفع/خفض الرأس
    required bool invertHorizontal,
    required bool invertVertical,
  }) async {
    await _channel.invokeMethod('updateSettings', {
      'dragLength': dragLength,
      'tapPointMode': tapPointMode,
      'tapX': tapX,
      'tapY': tapY,
      'turnThreshold': turnThreshold,
      'tiltThreshold': tiltThreshold,
      'invertHorizontal': invertHorizontal,
      'invertVertical': invertVertical,
    });
  }
}
