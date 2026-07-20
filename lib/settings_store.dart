import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  int dragLength;
  String tapPointMode; // center | custom
  double? tapX;
  double? tapY;
  double turnThreshold; // حساسية لف الرأس يمين/يسار (بالدرجات)
  double tiltThreshold; // حساسية رفع/خفض الرأس (بالدرجات)
  bool invertHorizontal; // لعكس يمين/يسار لو جاءت بالمقلوب
  bool invertVertical; // لعكس فوق/تحت لو جاءت بالمقلوب

  AppSettings({
    required this.dragLength,
    required this.tapPointMode,
    this.tapX,
    this.tapY,
    required this.turnThreshold,
    required this.tiltThreshold,
    required this.invertHorizontal,
    required this.invertVertical,
  });

  static AppSettings defaults() => AppSettings(
        dragLength: 150,
        tapPointMode: 'center',
        turnThreshold: 20,
        tiltThreshold: 15,
        invertHorizontal: false,
        invertVertical: false,
      );

  Map<String, dynamic> toJson() => {
        'dragLength': dragLength,
        'tapPointMode': tapPointMode,
        'tapX': tapX,
        'tapY': tapY,
        'turnThreshold': turnThreshold,
        'tiltThreshold': tiltThreshold,
        'invertHorizontal': invertHorizontal,
        'invertVertical': invertVertical,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        dragLength: json['dragLength'] as int,
        tapPointMode: json['tapPointMode'] as String,
        tapX: (json['tapX'] as num?)?.toDouble(),
        tapY: (json['tapY'] as num?)?.toDouble(),
        turnThreshold: (json['turnThreshold'] as num).toDouble(),
        tiltThreshold: (json['tiltThreshold'] as num).toDouble(),
        invertHorizontal: json['invertHorizontal'] as bool,
        invertVertical: json['invertVertical'] as bool,
      );
}

class SettingsStore {
  static const _key = 'app_settings_v1';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings.defaults();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
