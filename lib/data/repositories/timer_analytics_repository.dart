import '../../utils/command.dart';
import '../models/timer_analytics.dart';
import 'timer_session_repository.dart';

class TimerAnalyticsRepository {
  TimerAnalyticsRepository(this._timerSessionRepository);

  final TimerSessionRepository _timerSessionRepository;

  Future<Result<TimerAnalyticsSnapshot>> loadAnalytics({
    int recentDayCount = 7,
  }) async {
    final loadResult = await _timerSessionRepository.loadSessions();
    if (loadResult is Error<void>) {
      return Result.error(loadResult.exception);
    }

    try {
      final sessions = _timerSessionRepository.sessions;
      final recentDays = _recentDays(recentDayCount);
      final windowStart = recentDays.first;
      final windowEnd = recentDays.last.add(const Duration(days: 1));

      final recentSessions = sessions
          .where(
            (session) =>
                !session.startedAt.isBefore(windowStart) &&
                session.startedAt.isBefore(windowEnd),
          )
          .toList();

      final seriesTotals = <String, int>{};
      final labels = <String, String>{};
      final dailyByTask = <DateTime, Map<String, int>>{};
      final dailyTotals = <DateTime, int>{};
      final hourlyTotals = List<int>.filled(24, 0);

      for (final day in recentDays) {
        dailyByTask[day] = <String, int>{};
        dailyTotals[day] = 0;
      }

      for (final session in recentSessions) {
        final key = session.taskId;
        labels[key] = session.taskTitleSnapshot;
        seriesTotals[key] = (seriesTotals[key] ?? 0) + session.elapsedSeconds;

        final day = _startOfDay(session.startedAt);
        final dayMap = dailyByTask[day];
        if (dayMap != null) {
          dayMap[key] = (dayMap[key] ?? 0) + session.elapsedSeconds;
          dailyTotals[day] = (dailyTotals[day] ?? 0) + session.elapsedSeconds;
        }
      }

      for (final session in sessions) {
        hourlyTotals[session.startedAt.hour] += session.elapsedSeconds;
      }

      final sortedSeriesEntries = seriesTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final series = sortedSeriesEntries
          .map(
            (entry) => TimerAnalyticsSeries(
              key: entry.key,
              label: labels[entry.key] ?? entry.key,
              totalSeconds: entry.value,
            ),
          )
          .toList();

      final dailyStacks = recentDays
          .map(
            (day) => DailyTaskStack(
              day: day,
              secondsBySeries: Map.unmodifiable(dailyByTask[day] ?? const {}),
              totalSeconds: dailyTotals[day] ?? 0,
            ),
          )
          .toList();

      final hourlyBuckets = List.generate(
        24,
        (hour) => HourlyWorkBucket(
          hour: hour,
          totalSeconds: hourlyTotals[hour],
        ),
      );

      final dailyTotalBuckets = recentDays
          .map(
            (day) => DailyWorkBucket(
              day: day,
              totalSeconds: dailyTotals[day] ?? 0,
            ),
          )
          .toList();

      return Result.ok(
        TimerAnalyticsSnapshot(
          series: series,
          dailyTaskStacks: dailyStacks,
          hourlyBuckets: hourlyBuckets,
          dailyTotals: dailyTotalBuckets,
        ),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static List<DateTime> _recentDays(int count) {
    final today = _startOfDay(DateTime.now());
    return List.generate(
      count,
      (index) => today.subtract(Duration(days: count - index - 1)),
    );
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
