import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/alarm_service.dart';
import 'data/services/permission_service.dart';
import 'data/services/shared_preferences_service.dart';
import 'ui/main/main_viewmodel.dart';
import 'ui/settings/settings_viewmodel.dart';
import 'ui/setup/setup_viewmodel.dart';
import 'utils/command.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise alarm/notifications plugin early so scheduled alarms work.
  await AlarmService.init();

  final prefsService = SharedPreferencesService();
  final permissionService = PermissionService();

  final settingsRepository = SettingsRepository(prefsService);
  final taskRepository = TaskRepository();

  final onboardingResult = await settingsRepository.isOnboardingDone();
  final showSetup = switch (onboardingResult) {
    Ok<bool>(:final value) => !value,
    Error<bool>() => true,
  };

  final setupViewModel = SetupViewModel(
    settingsRepository: settingsRepository,
    permissionService: permissionService,
  );

  final mainViewModel = MainViewModel(
    settingsRepository: settingsRepository,
    taskRepository: taskRepository,
  );

  final settingsViewModel = SettingsViewModel(settingsRepository, permissionService);

  runApp(App(
    settingsRepository: settingsRepository,
    taskRepository: taskRepository,
    setupViewModel: setupViewModel,
    mainViewModel: mainViewModel,
    settingsViewModel: settingsViewModel,
    showSetup: showSetup,
  ));
}
