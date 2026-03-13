import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/export_repository.dart';
import 'data/repositories/screen_usage_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/timer_analytics_repository.dart';
import 'data/repositories/timer_session_repository.dart';
import 'data/services/alarm_service.dart';
import 'data/services/export_service.dart';
import 'data/services/permission_service.dart';
import 'data/services/screen_usage_platform_service.dart';
import 'data/services/shared_preferences_service.dart';
import 'ui/main/main_viewmodel.dart';
import 'ui/settings/settings_viewmodel.dart';
import 'ui/setup/setup_viewmodel.dart';
import 'utils/command.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AlarmService.init();

  final prefsService = SharedPreferencesService();
  final permissionService = PermissionService();

  final settingsRepository = SettingsRepository(prefsService);
  final screenUsageRepository =
      ScreenUsageRepository(ScreenUsagePlatformService());
  final taskRepository = TaskRepository();
  final timerSessionRepository = TimerSessionRepository();
  final timerAnalyticsRepository =
      TimerAnalyticsRepository(timerSessionRepository, screenUsageRepository);
  final exportRepository = ExportRepository(ExportService());


  final onboardingResult = await settingsRepository.isOnboardingDone();
  final showSetup = switch (onboardingResult) {
    Ok<bool>(:final value) => !value,
    Error<bool>() => true,
  };

  final setupViewModel = SetupViewModel(
    settingsRepository: settingsRepository,
    permissionService: permissionService,
    screenUsageRepository: screenUsageRepository,
  );

  final mainViewModel = MainViewModel(
    taskRepository: taskRepository,
    timerSessionRepository: timerSessionRepository,
    settingsRepository: settingsRepository,
  );

  final settingsViewModel = SettingsViewModel(
    settingsRepository,
    taskRepository,
    exportRepository,
  );

  runApp(App(
    settingsRepository: settingsRepository,
    screenUsageRepository: screenUsageRepository,
    taskRepository: taskRepository,
    timerSessionRepository: timerSessionRepository,
    timerAnalyticsRepository: timerAnalyticsRepository,
    setupViewModel: setupViewModel,
    mainViewModel: mainViewModel,
    settingsViewModel: settingsViewModel,
    showSetup: showSetup,
  ));
}
