import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _kOnboardingDone = 'onboardingDone';
  static const String _kAsrEnabled = 'asrEnabled';
  static const String _kAsrModelSettings = 'asrModelSettings';
  static const String _kThemeMode = 'themeMode';
  static const String _kRecommendationIndex = 'recommendationIndex';
  static const String _kRecommendationSignature = 'recommendationSignature';

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

  Future<int> getRecommendationIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRecommendationIndex) ?? 0;
  }

  Future<void> setRecommendationIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRecommendationIndex, value);
  }

  Future<String?> getRecommendationSignature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRecommendationSignature);
  }

  Future<void> setRecommendationSignature(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRecommendationSignature, value);
  }
}
