// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '老母亲';

  @override
  String get setupWelcomeTitle => '欢迎使用老母亲';

  @override
  String get setupWelcomeSubtitle => '你的任务管理助手';

  @override
  String get setupWelcomeButton => '开始设置';

  @override
  String get setupNotificationTitle => '通知权限';

  @override
  String get setupNotificationDesc => '老母亲需要通知权限，以便在任务截止前提醒你。';

  @override
  String get setupNotificationGrant => '授予通知权限';

  @override
  String get setupBackgroundTitle => '后台运行';

  @override
  String get setupBackgroundDesc => '允许老母亲在后台运行，以便持续追踪你的任务进度。';

  @override
  String get setupBackgroundGrant => '授予后台权限';

  @override
  String get setupAsrTitle => '语音输入';

  @override
  String get setupAsrDesc => '是否启用语音输入功能？你可以随时在设置中更改。';

  @override
  String get setupAsrEnable => '启用语音输入';

  @override
  String get setupAsrSkip => '暂不启用';

  @override
  String get setupSkip => '跳过';

  @override
  String get setupFinish => '完成';

  @override
  String setupStepOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get mainGreeting => '有什么我可以帮你的？';

  @override
  String get mainInputHint => '输入一个任务…';

  @override
  String get mainAskTasksChip => '今天做什么？';

  @override
  String get mainSetDeadline => '需要设定截止时间吗？';

  @override
  String get mainDeadlineButton => '设置时间';

  @override
  String get mainDeadlineSkip => '跳过';

  @override
  String mainTaskConfirmed(String title) {
    return '任务已添加：$title';
  }

  @override
  String mainTaskWithDeadline(String title, String deadline) {
    return '任务已添加：$title，截止时间：$deadline';
  }

  @override
  String mainStartTaskPrompt(String title) {
    return '开始执行：$title';
  }

  @override
  String get mainAskTasksResponse => '（任务建议功能即将推出）';

  @override
  String get mainMicUnavailable => '语音输入功能即将推出';

  @override
  String get mainAskTasksBtn => '今天做什么？';

  @override
  String get mainStartTimerBtn => '开始任务计时';

  @override
  String get mainStartTimerTitle => '开始计时';

  @override
  String get mainStartTimerHint => '输入任务名称';

  @override
  String get mainStartTimerConfirm => '开始';

  @override
  String get mainStartTimerCancel => '取消';

  @override
  String get asrModelNotConfigured => '请先在设置中配置ASR模型';

  @override
  String get asrRecordTitle => '语音输入';

  @override
  String get asrRecordHold => '按住说话';

  @override
  String get asrRecordStop => '完成';

  @override
  String get asrRecordCancel => '取消';

  @override
  String get asrRecordBtn => '语音输入';

  @override
  String get asrRecordProcessing => '正在识别…';

  @override
  String get asrRecordLoading => '正在加载模型…';

  @override
  String get asrRecordMicError => '麦克风错误';

  @override
  String get asrSettingsTitle => 'ASR 模型配置';

  @override
  String get asrSettingsModelType => '模型类型';

  @override
  String get asrSettingsEncoder => 'Encoder 模型文件';

  @override
  String get asrSettingsDecoder => 'Decoder 模型文件';

  @override
  String get asrSettingsJoiner => 'Joiner 模型文件';

  @override
  String get asrSettingsSingle => '模型文件';

  @override
  String get asrSettingsTokens => '词表文件 (tokens.txt)';

  @override
  String get asrSettingsSave => '保存配置';

  @override
  String get asrSettingsReset => '重置';

  @override
  String get asrSettingsSaved => '配置已保存';

  @override
  String get asrSettingsMissingFields => '请填写所有必填字段';

  @override
  String get asrSettingsPickFile => '选择文件';

  @override
  String get asrSettingsSelectPreset => '选择预设模型';

  @override
  String get asrSettingsModelFiles => '模型文件';

  @override
  String get asrSetupSkip => '跳过（稍后配置）';

  @override
  String get asrSettingsDownloadHint => '首次使用需要下载模型文件（约 100–400 MB），请保持网络连接。';

  @override
  String get settingsAsrModel => 'ASR 模型配置';

  @override
  String get settingsAsrModelDesc => '配置离线语音识别模型';

  @override
  String timerElapsed(String time) {
    return '已用时 $time';
  }

  @override
  String get timerPause => '暂停';

  @override
  String get timerResume => '继续';

  @override
  String get timerStop => '结束';

  @override
  String get timerStopped => '任务已结束';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAsr => '语音输入';

  @override
  String get settingsAsrDesc => '使用麦克风进行语音输入';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get asrRecordLive => '识别中…';

  @override
  String get asrRecordEmpty => '未识别到语音，请重试';

  @override
  String get downloadTitle => '下载模型';

  @override
  String get downloadDismiss => '完成';

  @override
  String get downloadExtracting => '正在解压…';

  @override
  String get downloadDone => '✓ 完成';

  @override
  String downloadPerc(String filename, double percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '$filename $percentString%';
  }

  @override
  String get asrSaveAndDownload => '保存并下载模型';

  @override
  String alarmScheduled(String title, String time) {
    return '已为「$title」设置 $time 的提醒';
  }

  @override
  String get mainSetAlarm => '设置提醒';

  @override
  String get mainNoAlarm => '不设置提醒';
}
