import 'package:flutter/foundation.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/services/alarm_service.dart';
import '../../data/services/permission_service.dart';
import '../../utils/command.dart';

enum SetupStep { welcome, notification, background, asr }

class SetupViewModel extends ChangeNotifier {
  SetupViewModel({
    required SettingsRepository settingsRepository,
    required PermissionService permissionService,
  })  : _settingsRepository = settingsRepository,
        _permissionService = permissionService {
    requestNotification = Command0(_requestNotification);
    requestBackground = Command0(_requestBackground);
    finishSetup = Command1<bool, void>(_finishSetup);
    nextStep = Command0(_nextStep);
  }

  final SettingsRepository _settingsRepository;
  final PermissionService _permissionService;

  SetupStep _currentStep = SetupStep.welcome;
  SetupStep get currentStep => _currentStep;

  int get stepIndex => SetupStep.values.indexOf(_currentStep);
  int get totalSteps => SetupStep.values.length;

  late final Command0<void> requestNotification;
  late final Command0<void> requestBackground;
  late final Command1<bool, void> finishSetup;
  late final Command0<void> nextStep;

  Future<Result<void>> _nextStep() async {
    final next = stepIndex + 1;
    if (next < totalSteps) {
      _currentStep = SetupStep.values[next];
      notifyListeners();
    }
    return Result.ok(null);
  }

  Future<Result<void>> _requestNotification() async {
    try {
      await _permissionService.requestNotification();
      await AlarmService.requestPermissions();
      return await _nextStep();
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> _requestBackground() async {
    try {
      await _permissionService.requestIgnoreBatteryOptimizations();
      return await _nextStep();
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> _finishSetup(bool asrEnabled) async {
    try {
      if (asrEnabled) {
        // Request microphone permission when user enables ASR in setup.
        await _permissionService.requestMicrophone();
      }
      await _settingsRepository.setAsrEnabled(asrEnabled);
      await _settingsRepository.setOnboardingDone();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
