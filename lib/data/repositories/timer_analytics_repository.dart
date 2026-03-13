import '../../utils/command.dart';
import '../models/screen_usage.dart';
import '../models/timer_analytics.dart';
import 'screen_usage_repository.dart';
import 'timer_session_repository.dart';

class TimerAnalyticsRepository {
  TimerAnalyticsRepository(
    this._timerSessionRepository,
    this._screenUsageRepository,
  );

  final TimerSessionRepository _timerSessionRepository;
  final ScreenUsageRepository _screenUsageRepository;

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

      final screenUsageResult = await _screenUsageRepository.loadRecentSnapshots(
        recentDayCount: recentDayCount,
      );
      final screenUsageAccessGranted = switch (screenUsageResult) {
        Ok<ScreenUsageLoadResult>(:final value) => value.granted,
        _ => false,
      };
      final screenSnapshots = switch (screenUsageResult) {
        Ok<ScreenUsageLoadResult>(:final value) => value.snapshots,
        _ => const <ScreenUsageDaySnapshot>[],
      };

      final screenSeriesTotals = <String, int>{};
      final screenLabels = <String, String>{};
      for (final snapshot in screenSnapshots) {
        for (final entry in snapshot.entries) {
          screenSeriesTotals[entry.packageName] =
              (screenSeriesTotals[entry.packageName] ?? 0) +
                  entry.totalForegroundMs;
          screenLabels[entry.packageName] = entry.appLabel;
        }
      }

      final sortedScreenSeries = screenSeriesTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topKeys = sortedScreenSeries.take(5).map((entry) => entry.key).toSet();
      const otherKey = '__other__';

      final otherTotalMs = sortedScreenSeries
          .skip(5)
          .fold<int>(0, (sum, entry) => sum + entry.value);

      final screenSeries = [
        ...sortedScreenSeries.take(5).map(
              (entry) => TimerAnalyticsSeries(
                key: entry.key,
                label: screenLabels[entry.key] ?? entry.key,
                totalSeconds: entry.value ~/ 1000,
              ),
            ),
        if (otherTotalMs > 0)
          const TimerAnalyticsSeries(
            key: otherKey,
            label: 'Other',
            totalSeconds: 0,
          ),
      ].map((series) {
        if (series.key != otherKey) return series;
        return TimerAnalyticsSeries(
          key: series.key,
          label: series.label,
          totalSeconds: otherTotalMs ~/ 1000,
        );
      }).toList();

      final screenSnapshotMap = {
        for (final snapshot in screenSnapshots) _startOfDay(snapshot.day): snapshot,
      };

      final screenDailyAppStacks = recentDays.map((day) {
        final snapshot = screenSnapshotMap[day];
        if (snapshot == null) {
          return DailyAppUsageStack(
            day: day,
            millisecondsBySeries: const {},
            totalMilliseconds: 0,
          );
        }

        final millisecondsBySeries = <String, int>{};
        var otherTotal = 0;
        for (final entry in snapshot.entries) {
          if (topKeys.contains(entry.packageName)) {
            millisecondsBySeries[entry.packageName] =
                (millisecondsBySeries[entry.packageName] ?? 0) +
                    entry.totalForegroundMs;
          } else {
            otherTotal += entry.totalForegroundMs;
          }
        }
        if (otherTotal > 0) {
          millisecondsBySeries[otherKey] = otherTotal;
        }
        return DailyAppUsageStack(
          day: day,
          millisecondsBySeries: millisecondsBySeries,
          totalMilliseconds: snapshot.totalForegroundMs,
        );
      }).toList();

      final screenDailyTotals = recentDays
          .map(
            (day) => DailyScreenTimeBucket(
              day: day,
              totalMilliseconds: screenSnapshotMap[day]?.totalForegroundMs ?? 0,
            ),
          )
          .toList();

      final workScreenComparisons = recentDays
          .map(
            (day) => DailyWorkScreenComparison(
              day: day,
              workSeconds: dailyTotals[day] ?? 0,
              screenMilliseconds:
                  screenSnapshotMap[day]?.totalForegroundMs ?? 0,
            ),
          )
          .toList();

      return Result.ok(
        TimerAnalyticsSnapshot(
          series: series,
          dailyTaskStacks: dailyStacks,
          hourlyBuckets: hourlyBuckets,
          dailyTotals: dailyTotalBuckets,
          screenUsageAccessGranted: screenUsageAccessGranted,
          screenSeries: screenSeries,
          screenDailyAppStacks: screenDailyAppStacks,
          screenDailyTotals: screenDailyTotals,
          workScreenComparisons: workScreenComparisons,
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
