class ScreenUsageAppEntry {
  const ScreenUsageAppEntry({
    required this.packageName,
    required this.appLabel,
    required this.totalForegroundMs,
  });

  final String packageName;
  final String appLabel;
  final int totalForegroundMs;

  factory ScreenUsageAppEntry.fromMap(Map<Object?, Object?> map) {
    return ScreenUsageAppEntry(
      packageName: map['packageName'] as String? ?? '',
      appLabel: map['appLabel'] as String? ?? '',
      totalForegroundMs: (map['totalForegroundMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScreenUsageDaySnapshot {
  const ScreenUsageDaySnapshot({
    required this.day,
    required this.totalForegroundMs,
    required this.entries,
  });

  final DateTime day;
  final int totalForegroundMs;
  final List<ScreenUsageAppEntry> entries;

  factory ScreenUsageDaySnapshot.fromMap(Map<Object?, Object?> map) {
    final rawEntries = map['entries'] as List<Object?>? ?? const [];
    return ScreenUsageDaySnapshot(
      day: DateTime.fromMillisecondsSinceEpoch(
        (map['dayStartEpochMs'] as num?)?.toInt() ?? 0,
      ),
      totalForegroundMs: (map['totalForegroundMs'] as num?)?.toInt() ?? 0,
      entries: rawEntries
          .map(
            (entry) => ScreenUsageAppEntry.fromMap(
              entry as Map<Object?, Object?>,
            ),
          )
          .toList(),
    );
  }
}

class ScreenUsageLoadResult {
  const ScreenUsageLoadResult({
    required this.granted,
    required this.snapshots,
  });

  final bool granted;
  final List<ScreenUsageDaySnapshot> snapshots;
}
