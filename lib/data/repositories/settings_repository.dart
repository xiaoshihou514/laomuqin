import 'dart:async';

import 'package:flutter/material.dart';

import '../services/shared_preferences_service.dart';
import '../../utils/command.dart';

class SettingsRepository {
  SettingsRepository(this._service);

  final SharedPreferencesService _service;

  final _asrController = StreamController<bool>.broadcast();
  final _asrModelController = StreamController<String?>.broadcast();
  final _themeModeController = StreamController<ThemeMode>.broadcast();

  Stream<bool> get asrStream => _asrController.stream;
  Stream<String?> get asrModelStream => _asrModelController.stream;
  Stream<ThemeMode> get themeModeStream => _themeModeController.stream;

  Future<Result<bool>> isOnboardingDone() async {
    try {
      return Result.ok(await _service.isOnboardingDone());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setOnboardingDone() async {
    try {
      await _service.setOnboardingDone(true);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<bool>> isAsrEnabled() async {
    try {
      return Result.ok(await _service.isAsrEnabled());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setAsrEnabled(bool value) async {
    try {
      await _service.setAsrEnabled(value);
      _asrController.add(value);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<String?>> getAsrModelSettings() async {
    try {
      return Result.ok(await _service.getAsrModelSettings());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setAsrModelSettings(String? json) async {
    try {
      await _service.setAsrModelSettings(json);
      _asrModelController.add(json);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<ThemeMode>> getThemeMode() async {
    try {
      final raw = await _service.getThemeMode();
      return Result.ok(_parseThemeMode(raw));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setThemeMode(ThemeMode mode) async {
    try {
      await _service.setThemeMode(_encodeThemeMode(mode));
      _themeModeController.add(mode);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static ThemeMode _parseThemeMode(String raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encodeThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };

  void dispose() {
    _asrController.close();
    _asrModelController.close();
    _themeModeController.close();
  }
}
