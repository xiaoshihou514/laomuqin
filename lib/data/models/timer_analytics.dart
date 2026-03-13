class TimerAnalyticsSeries {
  const TimerAnalyticsSeries({
    required this.key,
    required this.label,
    required this.totalSeconds,
  });

  final String key;
  final String label;
  final int totalSeconds;
}

class DailyTaskStack {
  const DailyTaskStack({
    required this.day,
    required this.secondsBySeries,
    required this.totalSeconds,
  });

  final DateTime day;
  final Map<String, int> secondsBySeries;
  final int totalSeconds;
}

class DailyAppUsageStack {
  const DailyAppUsageStack({
    required this.day,
    required this.millisecondsBySeries,
    required this.totalMilliseconds,
  });

  final DateTime day;
  final Map<String, int> millisecondsBySeries;
  final int totalMilliseconds;
}

class HourlyWorkBucket {
  const HourlyWorkBucket({
    required this.hour,
    required this.totalSeconds,
  });

  final int hour;
  final int totalSeconds;
}

class DailyWorkBucket {
  const DailyWorkBucket({
    required this.day,
    required this.totalSeconds,
  });

  final DateTime day;
  final int totalSeconds;
}

class DailyScreenTimeBucket {
  const DailyScreenTimeBucket({
    required this.day,
    required this.totalMilliseconds,
  });

  final DateTime day;
  final int totalMilliseconds;
}

class DailyWorkScreenComparison {
  const DailyWorkScreenComparison({
    required this.day,
    required this.workSeconds,
    required this.screenMilliseconds,
  });

  final DateTime day;
  final int workSeconds;
  final int screenMilliseconds;
}

class TimerAnalyticsSnapshot {
  const TimerAnalyticsSnapshot({
    required this.series,
    required this.dailyTaskStacks,
    required this.hourlyBuckets,
    required this.dailyTotals,
    required this.screenUsageAccessGranted,
    required this.screenSeries,
    required this.screenDailyAppStacks,
    required this.screenDailyTotals,
    required this.workScreenComparisons,
  });

  final List<TimerAnalyticsSeries> series;
  final List<DailyTaskStack> dailyTaskStacks;
  final List<HourlyWorkBucket> hourlyBuckets;
  final List<DailyWorkBucket> dailyTotals;
  final bool screenUsageAccessGranted;
  final List<TimerAnalyticsSeries> screenSeries;
  final List<DailyAppUsageStack> screenDailyAppStacks;
  final List<DailyScreenTimeBucket> screenDailyTotals;
  final List<DailyWorkScreenComparison> workScreenComparisons;

  bool get hasData =>
      dailyTaskStacks.any((item) => item.totalSeconds > 0) ||
      hourlyBuckets.any((item) => item.totalSeconds > 0) ||
      dailyTotals.any((item) => item.totalSeconds > 0) ||
      screenDailyAppStacks.any((item) => item.totalMilliseconds > 0) ||
      screenDailyTotals.any((item) => item.totalMilliseconds > 0);

  bool get hasScreenUsageData =>
      screenDailyAppStacks.any((item) => item.totalMilliseconds > 0) ||
      screenDailyTotals.any((item) => item.totalMilliseconds > 0);
}
