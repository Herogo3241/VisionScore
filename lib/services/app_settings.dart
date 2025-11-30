import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }


  static bool get useOptimized =>
      _prefs?.getBool("optimized") ?? false;

  static Future<void> setOptimized(bool v) async =>
      await _prefs?.setBool("optimized", v);


  static double get duration =>
      _prefs?.getDouble("duration") ?? 8.0;

  static Future<void> setDuration(double v) async =>
      await _prefs?.setDouble("duration", v);
      
}
