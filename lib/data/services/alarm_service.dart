import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Service for scheduling and cancelling local alarm notifications tied to
/// task deadlines.
abstract class AlarmService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Must be called once at app startup to initialise the plugin.
  ///
  /// Does NOT request permissions — call [requestPermissions] separately
  /// at the appropriate point in the onboarding flow.
  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: '打开');
    const settings = InitializationSettings(android: android, linux: linux);

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Requests notification and exact-alarm permissions on Android.
  ///
  /// Should be called during the setup notification step, not at startup.
  static Future<void> requestPermissions() async {
    await init();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Schedules a notification for [taskTitle] at [deadline].
  ///
  /// [notificationId] must be a stable unique integer per task.
  static Future<void> scheduleTaskAlarm({
    required int notificationId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    await init();

    final scheduledDate = tz.TZDateTime.from(deadline, tz.local);

    // Skip if the deadline is in the past.
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'task_deadline',
      '任务截止提醒',
      channelDescription: '在任务截止时间到达时发送提醒',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: '任务截止提醒',
      body: taskTitle,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancels a previously scheduled alarm.
  static Future<void> cancelAlarm(int notificationId) async {
    await init();
    await _plugin.cancel(id: notificationId);
  }

  /// Derives a stable int notification ID from a string task id.
  static int notificationIdFor(String taskId) =>
      taskId.hashCode.abs() % 2147483647;
}
