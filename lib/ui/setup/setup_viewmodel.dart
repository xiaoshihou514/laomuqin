import 'package:flutter/foundation.dart';

import '../../data/repositories/screen_usage_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/alarm_service.dart';
import '../../data/services/permission_service.dart';
import '../../utils/command.dart';

enum SetupStep { welcome, notification, background, usageAccess }

class SetupViewModel extends ChangeNotifier {
  SetupViewModel({
    required SettingsRepository settingsRepository,
    required PermissionService permissionService,
    required ScreenUsageRepository screenUsageRepository,
  })  : _settingsRepository = settingsRepository,
        _permissionService = permissionService,
        _screenUsageRepository = screenUsageRepository {
    requestNotification = Command0(_requestNotification);
    requestBackground = Command0(_requestBackground);
    openUsageAccess = Command0(_openUsageAccess);
    checkUsageAccess = Command0(_checkUsageAccess);
    finishSetup = Command0(_finishSetup);
    nextStep = Command0(_nextStep);
  }

  final SettingsRepository _settingsRepository;
  final PermissionService _permissionService;
  final ScreenUsageRepository _screenUsageRepository;

  SetupStep _currentStep = SetupStep.welcome;
  SetupStep get currentStep => _currentStep;

  bool _usageAccessGranted = false;
  bool get usageAccessGranted => _usageAccessGranted;

  int get stepIndex => SetupStep.values.indexOf(_currentStep);
  int get totalSteps => SetupStep.values.length;

  late final Command0<void> requestNotification;
  late final Command0<void> requestBackground;
  late final Command0<void> openUsageAccess;
  late final Command0<void> checkUsageAccess;
  late final Command0<void> finishSetup;
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

  Future<Result<void>> _openUsageAccess() async {
    return _screenUsageRepository.openUsageAccessSettings();
  }

  Future<Result<void>> _checkUsageAccess() async {
    final result = await _screenUsageRepository.isUsageAccessGranted();
    if (result case Ok<bool>(:final value)) {
      _usageAccessGranted = value;
      if (value) {
        await _screenUsageRepository.ensureBackgroundCollectionScheduled();
      }
      notifyListeners();
      return Result.ok(null);
    }
    if (result case Error<bool>(:final exception)) {
      return Result.error(exception);
    }
    return Result.ok(null);
  }

  Future<Result<void>> _finishSetup() async {
    try {
      if (_usageAccessGranted) {
        await _screenUsageRepository.ensureBackgroundCollectionScheduled();
      }
      await _settingsRepository.setOnboardingDone();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
