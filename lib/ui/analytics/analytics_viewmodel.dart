import 'package:flutter/material.dart';

import '../../data/models/timer_analytics.dart';
import '../../data/repositories/timer_analytics_repository.dart';
import '../../utils/command.dart';

class AnalyticsViewModel extends ChangeNotifier {
  AnalyticsViewModel(this._repository) {
    load = Command0(_load)..execute();
  }

  final TimerAnalyticsRepository _repository;

  TimerAnalyticsSnapshot? _snapshot;
  TimerAnalyticsSnapshot? get snapshot => _snapshot;

  late final Command0<void> load;

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
}
