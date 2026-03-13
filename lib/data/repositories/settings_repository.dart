import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils/command.dart';
import '../services/shared_preferences_service.dart';

class SettingsRepository {
  SettingsRepository(this._service);

  final SharedPreferencesService _service;

  final _themeModeController = StreamController<ThemeMode>.broadcast();

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

  Future<Result<int>> getRecommendationIndex() async {
    try {
      return Result.ok(await _service.getRecommendationIndex());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setRecommendationIndex(int index) async {
    try {
      await _service.setRecommendationIndex(index);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<String?>> getRecommendationSignature() async {
    try {
      return Result.ok(await _service.getRecommendationSignature());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setRecommendationSignature(String signature) async {
    try {
      await _service.setRecommendationSignature(signature);
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
    _themeModeController.close();
  }
}
