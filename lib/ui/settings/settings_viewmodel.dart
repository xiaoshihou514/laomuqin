import 'package:flutter/material.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/services/permission_service.dart';
import '../../utils/command.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._settingsRepository, this._permissionService) {
    load = Command0(_load)..execute();
    toggleAsr = Command0(_toggleAsr);
    saveAsrModelSettings = Command1<String?, void>(_saveAsrModelSettings);
    setThemeMode = Command1<ThemeMode, void>(_setThemeMode);
  }

  final SettingsRepository _settingsRepository;
  final PermissionService _permissionService;

  bool _asrEnabled = false;
  bool get asrEnabled => _asrEnabled;

  String? _asrModelSettingsJson;
  String? get asrModelSettingsJson => _asrModelSettingsJson;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  late final Command0<void> load;
  late final Command0<void> toggleAsr;
  late final Command1<String?, void> saveAsrModelSettings;
  late final Command1<ThemeMode, void> setThemeMode;

  Future<Result<void>> _load() async {
    final asrResult = await _settingsRepository.isAsrEnabled();
    if (asrResult is Ok<bool>) {
      _asrEnabled = asrResult.value;
    }
    final modelResult = await _settingsRepository.getAsrModelSettings();
    if (modelResult is Ok<String?>) {
      _asrModelSettingsJson = modelResult.value;
    }
    final themeModeResult = await _settingsRepository.getThemeMode();
    if (themeModeResult is Ok<ThemeMode>) {
      _themeMode = themeModeResult.value;
    }
    notifyListeners();
    return Result.ok(null);
  }

  Future<Result<void>> _toggleAsr() async {
    _asrEnabled = !_asrEnabled;
    // Request microphone permission when user enables ASR.
    if (_asrEnabled) {
      await _permissionService.requestMicrophone();
    }
    notifyListeners();
    return _settingsRepository.setAsrEnabled(_asrEnabled);
  }

  Future<Result<void>> _saveAsrModelSettings(String? json) async {
    final result = await _settingsRepository.setAsrModelSettings(json);
    if (result is Ok) {
      _asrModelSettingsJson = json;
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> _setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    return _settingsRepository.setThemeMode(mode);
  }
}
