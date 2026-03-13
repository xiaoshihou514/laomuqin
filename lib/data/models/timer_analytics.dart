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

class TimerAnalyticsSnapshot {
  const TimerAnalyticsSnapshot({
    required this.series,
    required this.dailyTaskStacks,
    required this.hourlyBuckets,
    required this.dailyTotals,
  });

  final List<TimerAnalyticsSeries> series;
  final List<DailyTaskStack> dailyTaskStacks;
  final List<HourlyWorkBucket> hourlyBuckets;
  final List<DailyWorkBucket> dailyTotals;

  bool get hasData =>
      dailyTaskStacks.any((item) => item.totalSeconds > 0) ||
      hourlyBuckets.any((item) => item.totalSeconds > 0) ||
      dailyTotals.any((item) => item.totalSeconds > 0);
}
