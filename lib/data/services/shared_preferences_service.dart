import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _kOnboardingDone = 'onboardingDone';
  static const String _kAsrEnabled = 'asrEnabled';
  static const String _kAsrModelSettings = 'asrModelSettings';
  static const String _kThemeMode = 'themeMode';

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, value);
  }

  Future<bool> isAsrEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAsrEnabled) ?? false;
  }

  Future<void> setAsrEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAsrEnabled, value);
  }

  Future<String?> getAsrModelSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAsrModelSettings);
  }

  Future<void> setAsrModelSettings(String? json) async {
    final prefs = await SharedPreferences.getInstance();
    if (json == null) {
      await prefs.remove(_kAsrModelSettings);
    } else {
      await prefs.setString(_kAsrModelSettings, json);
    }
  }

  /// Returns stored theme mode string: 'system', 'light', or 'dark'.
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode);
  }
}
