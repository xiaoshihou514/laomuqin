import 'package:flutter/material.dart';

import '../../data/models/timer_analytics.dart';
import '../../data/repositories/screen_usage_repository.dart';
import '../../data/repositories/timer_analytics_repository.dart';
import '../../utils/command.dart';

class AnalyticsViewModel extends ChangeNotifier {
  AnalyticsViewModel(this._repository, this._screenUsageRepository) {
    load = Command0(_load)..execute();
    openUsageAccess = Command0(_openUsageAccess);
  }

  final TimerAnalyticsRepository _repository;
  final ScreenUsageRepository _screenUsageRepository;

  TimerAnalyticsSnapshot? _snapshot;
  TimerAnalyticsSnapshot? get snapshot => _snapshot;

  late final Command0<void> load;
  late final Command0<void> openUsageAccess;

  Future<Result<void>> _load() async {
    final result = await _repository.loadAnalytics();
    if (result case Ok<TimerAnalyticsSnapshot>(:final value)) {
      _snapshot = value;
      notifyListeners();
      return Result.ok(null);
    }
    if (result case Error<TimerAnalyticsSnapshot>(:final exception)) {
      return Result.error(exception);
    }
    return Result.ok(null);
  }

  Future<Result<void>> _openUsageAccess() async {
    return _screenUsageRepository.openUsageAccessSettings();
  }
}
