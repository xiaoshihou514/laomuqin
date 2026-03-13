import 'package:flutter/material.dart';

import '../../data/repositories/export_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../utils/command.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(
    this._settingsRepository,
    this._taskRepository,
    this._exportRepository,
  ) {
    load = Command0(_load)..execute();
    setThemeMode = Command1<ThemeMode, void>(_setThemeMode);
    exportTasks = Command0(_exportTasks);
  }

  final SettingsRepository _settingsRepository;
  final TaskRepository _taskRepository;
  final ExportRepository _exportRepository;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  String? _lastExportPath;
  String? get lastExportPath => _lastExportPath;

  late final Command0<void> load;
  late final Command1<ThemeMode, void> setThemeMode;
  late final Command0<String> exportTasks;

  Future<Result<void>> _load() async {
    final themeModeResult = await _settingsRepository.getThemeMode();
    if (themeModeResult is Ok<ThemeMode>) {
      _themeMode = themeModeResult.value;
    }
    notifyListeners();
    return Result.ok(null);
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
