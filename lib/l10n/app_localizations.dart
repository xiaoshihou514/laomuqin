import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In zh, this message translates to:
  /// **'老母亲'**
  String get appTitle;

  /// Setup welcome title
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用老母亲'**
  String get setupWelcomeTitle;

  /// Setup welcome subtitle
  ///
  /// In zh, this message translates to:
  /// **'你的任务管理助手'**
  String get setupWelcomeSubtitle;

  /// Button to start setup
  ///
  /// In zh, this message translates to:
  /// **'开始设置'**
  String get setupWelcomeButton;

  /// Setup step: notification permission title
  ///
  /// In zh, this message translates to:
  /// **'通知权限'**
  String get setupNotificationTitle;

  /// Setup step: notification permission description
  ///
  /// In zh, this message translates to:
  /// **'老母亲需要通知权限，以便在任务截止前提醒你。'**
  String get setupNotificationDesc;

  /// Grant notification permission button
  ///
  /// In zh, this message translates to:
  /// **'授予通知权限'**
  String get setupNotificationGrant;

  /// Setup step: background permission title
  ///
  /// In zh, this message translates to:
  /// **'后台运行'**
  String get setupBackgroundTitle;

  /// Setup step: background permission description
  ///
  /// In zh, this message translates to:
  /// **'允许老母亲在后台运行，以便持续追踪你的任务进度。'**
  String get setupBackgroundDesc;

  /// Grant background permission button
  ///
  /// In zh, this message translates to:
  /// **'授予后台权限'**
  String get setupBackgroundGrant;

  /// Setup step: ASR preference title
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get setupAsrTitle;

  /// Setup step: ASR preference description
  ///
  /// In zh, this message translates to:
  /// **'是否启用语音输入功能？你可以随时在设置中更改。'**
  String get setupAsrDesc;

  /// Enable ASR button
  ///
  /// In zh, this message translates to:
  /// **'启用语音输入'**
  String get setupAsrEnable;

  /// Skip ASR button
  ///
  /// In zh, this message translates to:
  /// **'暂不启用'**
  String get setupAsrSkip;

  /// Skip current setup step
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get setupSkip;

  /// Finish setup button
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get setupFinish;

  /// Step indicator e.g. 2/4
  ///
  /// In zh, this message translates to:
  /// **'{current}/{total}'**
  String setupStepOf(int current, int total);

  /// Initial system greeting in chat
  ///
  /// In zh, this message translates to:
  /// **'有什么我可以帮你的？'**
  String get mainGreeting;

  /// Chat input placeholder text
  ///
  /// In zh, this message translates to:
  /// **'输入一个任务…'**
  String get mainInputHint;

  /// Quick-action chip to ask for task suggestions
  ///
  /// In zh, this message translates to:
  /// **'今天做什么？'**
  String get mainAskTasksChip;

  /// System message asking about task deadline
  ///
  /// In zh, this message translates to:
  /// **'需要设定截止时间吗？'**
  String get mainSetDeadline;

  /// Button to open deadline picker
  ///
  /// In zh, this message translates to:
  /// **'设置时间'**
  String get mainDeadlineButton;

  /// Skip setting deadline
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get mainDeadlineSkip;

  /// System confirmation after task added
  ///
  /// In zh, this message translates to:
  /// **'任务已添加：{title}'**
  String mainTaskConfirmed(String title);

  /// System confirmation after task added with deadline
  ///
  /// In zh, this message translates to:
  /// **'任务已添加：{title}，截止时间：{deadline}'**
  String mainTaskWithDeadline(String title, String deadline);

  /// Message shown when user starts a task
  ///
  /// In zh, this message translates to:
  /// **'开始执行：{title}'**
  String mainStartTaskPrompt(String title);

  /// Placeholder response for ask-tasks feature
  ///
  /// In zh, this message translates to:
  /// **'（任务建议功能即将推出）'**
  String get mainAskTasksResponse;

  /// Snackbar when mic button tapped but ASR not available
  ///
  /// In zh, this message translates to:
  /// **'语音输入功能即将推出'**
  String get mainMicUnavailable;

  /// Big button to ask for task suggestions
  ///
  /// In zh, this message translates to:
  /// **'今天做什么？'**
  String get mainAskTasksBtn;

  /// Big button to start a task timer
  ///
  /// In zh, this message translates to:
  /// **'开始任务计时'**
  String get mainStartTimerBtn;

  /// Dialog title for starting a task timer
  ///
  /// In zh, this message translates to:
  /// **'开始计时'**
  String get mainStartTimerTitle;

  /// Hint for task name in start timer dialog
  ///
  /// In zh, this message translates to:
  /// **'输入任务名称'**
  String get mainStartTimerHint;

  /// Confirm starting the timer
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get mainStartTimerConfirm;

  /// Cancel starting the timer
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get mainStartTimerCancel;

  /// Snackbar when mic tapped but model not configured
  ///
  /// In zh, this message translates to:
  /// **'请先在设置中配置ASR模型'**
  String get asrModelNotConfigured;

  /// Title of the ASR recording bottom sheet
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get asrRecordTitle;

  /// Hint shown on mic button before user starts recording
  ///
  /// In zh, this message translates to:
  /// **'按住说话'**
  String get asrRecordHold;

  /// Stop recording and transcribe button
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get asrRecordStop;

  /// Cancel recording button
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get asrRecordCancel;

  /// Big button label for starting ASR voice input
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get asrRecordBtn;

  /// Processing indicator during ASR transcription
  ///
  /// In zh, this message translates to:
  /// **'正在识别…'**
  String get asrRecordProcessing;

  /// Loading indicator while ASR model is initializing
  ///
  /// In zh, this message translates to:
  /// **'正在加载模型…'**
  String get asrRecordLoading;

  /// Error title when microphone fails to open
  ///
  /// In zh, this message translates to:
  /// **'麦克风错误'**
  String get asrRecordMicError;

  /// ASR settings page title
  ///
  /// In zh, this message translates to:
  /// **'ASR 模型配置'**
  String get asrSettingsTitle;

  /// Label for model type dropdown
  ///
  /// In zh, this message translates to:
  /// **'模型类型'**
  String get asrSettingsModelType;

  /// Label for encoder file picker
  ///
  /// In zh, this message translates to:
  /// **'Encoder 模型文件'**
  String get asrSettingsEncoder;

  /// Label for decoder file picker
  ///
  /// In zh, this message translates to:
  /// **'Decoder 模型文件'**
  String get asrSettingsDecoder;

  /// Label for joiner file picker
  ///
  /// In zh, this message translates to:
  /// **'Joiner 模型文件'**
  String get asrSettingsJoiner;

  /// Label for single model file picker (CTC)
  ///
  /// In zh, this message translates to:
  /// **'模型文件'**
  String get asrSettingsSingle;

  /// Label for tokens file picker
  ///
  /// In zh, this message translates to:
  /// **'词表文件 (tokens.txt)'**
  String get asrSettingsTokens;

  /// Save ASR settings button
  ///
  /// In zh, this message translates to:
  /// **'保存配置'**
  String get asrSettingsSave;

  /// Reset ASR settings button
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get asrSettingsReset;

  /// Snackbar when ASR settings saved successfully
  ///
  /// In zh, this message translates to:
  /// **'配置已保存'**
  String get asrSettingsSaved;

  /// Validation error for missing required fields
  ///
  /// In zh, this message translates to:
  /// **'请填写所有必填字段'**
  String get asrSettingsMissingFields;

  /// File picker button label
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get asrSettingsPickFile;

  /// Preset selection section title in ASR settings
  ///
  /// In zh, this message translates to:
  /// **'选择预设模型'**
  String get asrSettingsSelectPreset;

  /// Model files section title in ASR settings
  ///
  /// In zh, this message translates to:
  /// **'模型文件'**
  String get asrSettingsModelFiles;

  /// Skip ASR model setup during onboarding
  ///
  /// In zh, this message translates to:
  /// **'跳过（稍后配置）'**
  String get asrSetupSkip;

  /// Hint about downloading model files
  ///
  /// In zh, this message translates to:
  /// **'首次使用需要下载模型文件（约 100–400 MB），请保持网络连接。'**
  String get asrSettingsDownloadHint;

  /// Settings cell: navigate to ASR model configuration
  ///
  /// In zh, this message translates to:
  /// **'ASR 模型配置'**
  String get settingsAsrModel;

  /// Settings cell description for ASR model
  ///
  /// In zh, this message translates to:
  /// **'配置离线语音识别模型'**
  String get settingsAsrModelDesc;

  /// Elapsed time label
  ///
  /// In zh, this message translates to:
  /// **'已用时 {time}'**
  String timerElapsed(String time);

  /// Timer pause button
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get timerPause;

  /// Timer resume button
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get timerResume;

  /// Timer stop button
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get timerStop;

  /// Message shown when timer is stopped
  ///
  /// In zh, this message translates to:
  /// **'任务已结束'**
  String get timerStopped;

  /// Settings page title
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// Settings: ASR toggle label
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get settingsAsr;

  /// Settings: ASR toggle description
  ///
  /// In zh, this message translates to:
  /// **'使用麦克风进行语音输入'**
  String get settingsAsrDesc;

  /// Settings: theme label
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get settingsTheme;

  /// Settings: theme option - system
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsThemeSystem;

  /// Settings: theme option - light
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get settingsThemeLight;

  /// Settings: theme option - dark
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settingsThemeDark;

  /// Live ASR partial result label
  ///
  /// In zh, this message translates to:
  /// **'识别中…'**
  String get asrRecordLive;

  /// Snackbar when ASR returns empty
  ///
  /// In zh, this message translates to:
  /// **'未识别到语音，请重试'**
  String get asrRecordEmpty;

  /// Model download dialog title
  ///
  /// In zh, this message translates to:
  /// **'下载模型'**
  String get downloadTitle;

  /// Button to dismiss download dialog when done
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get downloadDismiss;

  /// Download stage: extracting
  ///
  /// In zh, this message translates to:
  /// **'正在解压…'**
  String get downloadExtracting;

  /// Download stage: done
  ///
  /// In zh, this message translates to:
  /// **'✓ 完成'**
  String get downloadDone;

  /// Download progress line
  ///
  /// In zh, this message translates to:
  /// **'{filename} {percent}%'**
  String downloadPerc(String filename, double percent);

  /// Button: save preset and download models
  ///
  /// In zh, this message translates to:
  /// **'保存并下载模型'**
  String get asrSaveAndDownload;

  /// Confirmation message after alarm scheduled
  ///
  /// In zh, this message translates to:
  /// **'已为「{title}」设置 {time} 的提醒'**
  String alarmScheduled(String title, String time);

  /// Button: schedule an alarm for this task deadline
  ///
  /// In zh, this message translates to:
  /// **'设置提醒'**
  String get mainSetAlarm;

  /// Button: skip alarm, just save deadline
  ///
  /// In zh, this message translates to:
  /// **'不设置提醒'**
  String get mainNoAlarm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
