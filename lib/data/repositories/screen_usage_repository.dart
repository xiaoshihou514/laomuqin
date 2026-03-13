import '../../utils/command.dart';
import '../models/screen_usage.dart';
import '../services/screen_usage_platform_service.dart';

class ScreenUsageRepository {
  ScreenUsageRepository(this._service);

  final ScreenUsagePlatformService _service;

  Future<Result<bool>> isUsageAccessGranted() async {
    try {
      return Result.ok(await _service.isUsageAccessGranted());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> openUsageAccessSettings() async {
    try {
      await _service.openUsageAccessSettings();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> scheduleMidnightCollection() async {
    try {
      await _service.scheduleMidnightCollection();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> ensureBackgroundCollectionScheduled() async {
    final grantedResult = await isUsageAccessGranted();
    if (grantedResult case Ok<bool>(:final value) when value) {
      return scheduleMidnightCollection();
    }
    if (grantedResult case Error<bool>(:final exception)) {
      return Result.error(exception);
    }
    return Result.ok(null);
  }

  Future<Result<ScreenUsageLoadResult>> loadRecentSnapshots({
    int recentDayCount = 7,
  }) async {
    try {
      final raw = await _service.getRecentSnapshots(days: recentDayCount);
      final granted = raw['granted'] as bool? ?? false;
      final snapshotsRaw = raw['snapshots'] as List<Object?>? ?? const [];
      final snapshots = snapshotsRaw
          .map(
            (item) => ScreenUsageDaySnapshot.fromMap(
              item as Map<Object?, Object?>,
            ),
          )
          .toList();
      return Result.ok(
        ScreenUsageLoadResult(granted: granted, snapshots: snapshots),
      );
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
