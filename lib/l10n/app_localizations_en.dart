// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LaoMuQin';

  @override
  String get setupWelcomeTitle => 'Welcome to LaoMuQin';

  @override
  String get setupWelcomeSubtitle => 'Your personal task assistant';

  @override
  String get setupWelcomeButton => 'Get Started';

  @override
  String get setupNotificationTitle => 'Notifications';

  @override
  String get setupNotificationDesc =>
      'LaoMuQin needs notification permission to remind you before tasks are due.';

  @override
  String get setupNotificationGrant => 'Grant Notification Permission';

  @override
  String get setupBackgroundTitle => 'Background Access';

  @override
  String get setupBackgroundDesc =>
      'Allow LaoMuQin to run in the background to continuously track your tasks.';

  @override
  String get setupBackgroundGrant => 'Grant Background Permission';

  @override
  String get setupAsrTitle => 'Voice Input';

  @override
  String get setupAsrDesc =>
      'Would you like to enable voice input? You can change this anytime in Settings.';

  @override
  String get setupAsrEnable => 'Enable Voice Input';

  @override
  String get setupAsrSkip => 'Not Now';

  @override
  String get setupSkip => 'Skip';

  @override
  String get setupFinish => 'Done';

  @override
  String setupStepOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get mainGreeting => 'How can I help you?';

  @override
  String get mainInputHint => 'Enter a task…';

  @override
  String get mainAskTasksChip => 'What to do today?';

  @override
  String get mainSetDeadline => 'Would you like to set a deadline?';

  @override
  String get mainDeadlineButton => 'Set Time';

  @override
  String get mainDeadlineSkip => 'Skip';

  @override
  String mainTaskConfirmed(String title) {
    return 'Task added: $title';
  }

  @override
  String mainTaskWithDeadline(String title, String deadline) {
    return 'Task added: $title, due $deadline';
  }

  @override
  String mainStartTaskPrompt(String title) {
    return 'Starting: $title';
  }

  @override
  String get mainAskTasksResponse => '(Task suggestions coming soon)';

  @override
  String get mainMicUnavailable => 'Voice input coming soon';

  @override
  String get mainAskTasksBtn => 'What to do today?';

  @override
  String get mainStartTimerBtn => 'Start Task Timer';

  @override
  String get mainStartTimerTitle => 'Start Timer';

  @override
  String get mainStartTimerHint => 'Enter task name';

  @override
  String get mainStartTimerConfirm => 'Start';

  @override
  String get mainStartTimerCancel => 'Cancel';

  @override
  String get mainStartTimerPickTask => 'Choose a task to time';

  @override
  String get mainStartTimerNoTasks => 'There are no pending tasks to time yet';

  @override
  String get mainStartTimerNoDeadline => 'No deadline';

  @override
  String mainStartTimerDeadline(String deadline) {
    return 'Due $deadline';
  }

  @override
  String get asrModelNotConfigured =>
      'Please configure an ASR model in Settings first';

  @override
  String get asrRecordTitle => 'Voice Input';

  @override
  String get asrRecordHold => 'Hold to speak';

  @override
  String get asrRecordStop => 'Done';

  @override
  String get asrRecordCancel => 'Cancel';

  @override
  String get asrRecordBtn => 'Record Voice';

  @override
  String get asrRecordProcessing => 'Recognizing…';

  @override
  String get asrRecordLoading => 'Loading model…';

  @override
  String get asrRecordMicError => 'Microphone Error';

  @override
  String get asrSettingsTitle => 'ASR Model Settings';

  @override
  String get asrSettingsModelType => 'Model Type';

  @override
  String get asrSettingsEncoder => 'Encoder Model File';

  @override
  String get asrSettingsDecoder => 'Decoder Model File';

  @override
  String get asrSettingsJoiner => 'Joiner Model File';

  @override
  String get asrSettingsSingle => 'Model File';

  @override
  String get asrSettingsTokens => 'Tokens File (tokens.txt)';

  @override
  String get asrSettingsSave => 'Save Configuration';

  @override
  String get asrSettingsReset => 'Reset';

  @override
  String get asrSettingsSaved => 'Configuration saved';

  @override
  String get asrSettingsMissingFields => 'Please fill in all required fields';

  @override
  String get asrSettingsPickFile => 'Pick File';

  @override
  String get asrSettingsSelectPreset => 'Select Model Preset';

  @override
  String get asrSettingsModelFiles => 'Model Files';

  @override
  String get asrSetupSkip => 'Skip (configure later)';

  @override
  String get asrSettingsDownloadHint =>
      'First use requires downloading model files (~100–400 MB). Please stay connected.';

  @override
  String get settingsAsrModel => 'ASR Model Settings';

  @override
  String get settingsAsrModelDesc =>
      'Configure offline speech recognition model';

  @override
  String timerElapsed(String time) {
    return 'Elapsed $time';
  }

  @override
  String get timerPause => 'Pause';

  @override
  String get timerResume => 'Resume';

  @override
  String get timerStop => 'Stop';

  @override
  String get timerStopped => 'Task ended';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAsr => 'Voice Input';

  @override
  String get settingsAsrDesc => 'Use microphone for voice input';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAnalytics => 'Work analytics';

  @override
  String get settingsAnalyticsDesc => 'View recent timer-based work charts';

  @override
  String get settingsExportTasks => 'Export tasks';

  @override
  String get settingsExportTasksDesc =>
      'Write the current task list to a JSON file in Downloads';

  @override
  String settingsExportTasksSuccess(String path) {
    return 'Tasks exported to $path';
  }

  @override
  String get settingsExportTasksFailed => 'Failed to export tasks';

  @override
  String get analyticsTitle => 'Work analytics';

  @override
  String get analyticsEmptyTitle => 'No timer data yet';

  @override
  String get analyticsEmptyDesc =>
      'Start and stop a few task timers, then come back to see your work patterns.';

  @override
  String get analyticsRecentByTaskTitle => 'Recent work by day';

  @override
  String get analyticsRecentByTaskDesc =>
      'Stacked bars show how much time you worked each recent day and on which tasks.';

  @override
  String get analyticsHourlyTitle => 'Usual work hours';

  @override
  String get analyticsHourlyDesc =>
      'Bars show how much tracked time started in each hour of the day.';

  @override
  String get analyticsDailyTotalsTitle => 'Recent daily totals';

  @override
  String get analyticsDailyTotalsDesc =>
      'Bars show your total tracked work time for each recent date.';

  @override
  String get asrRecordLive => 'Recognising…';

  @override
  String get asrRecordEmpty => 'Speech not recognised, please try again';

  @override
  String get downloadTitle => 'Downloading Models';

  @override
  String get downloadDismiss => 'Done';

  @override
  String get downloadExtracting => 'Extracting…';

  @override
  String get downloadDone => '✓ Done';

  @override
  String downloadPerc(String filename, double percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$filename $percentString%';
  }

  @override
  String get asrSaveAndDownload => 'Save & Download Model';

  @override
  String alarmScheduled(String title, String time) {
    return 'Reminder set for \"$title\" at $time';
  }

  @override
  String get mainSetAlarm => 'Set Reminder';

  @override
  String get mainNoAlarm => 'No Reminder';
}
