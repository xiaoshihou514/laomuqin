import 'package:flutter/material.dart';

import '../../data/repositories/export_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/services/permission_service.dart';
import '../../utils/command.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(
    this._settingsRepository,
    this._permissionService,
    this._taskRepository,
    this._exportRepository,
  ) {
    load = Command0(_load)..execute();
    toggleAsr = Command0(_toggleAsr);
    saveAsrModelSettings = Command1<String?, void>(_saveAsrModelSettings);
    setThemeMode = Command1<ThemeMode, void>(_setThemeMode);
    exportTasks = Command0(_exportTasks);
  }

  final SettingsRepository _settingsRepository;
  final PermissionService _permissionService;
  final TaskRepository _taskRepository;
  final ExportRepository _exportRepository;

  bool _asrEnabled = false;
  bool get asrEnabled => _asrEnabled;

  String? _asrModelSettingsJson;
  String? get asrModelSettingsJson => _asrModelSettingsJson;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  String? _lastExportPath;
  String? get lastExportPath => _lastExportPath;

  late final Command0<void> load;
  late final Command0<void> toggleAsr;
  late final Command1<String?, void> saveAsrModelSettings;
  late final Command1<ThemeMode, void> setThemeMode;
  late final Command0<String> exportTasks;

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

  Future<Result<String>> _exportTasks() async {
    final result = await _exportRepository.exportTasksToDownloads(
      _taskRepository.tasks,
    );
    if (result case Ok<String>(:final value)) {
      _lastExportPath = value;
      notifyListeners();
    }
    return result;
  }
}
