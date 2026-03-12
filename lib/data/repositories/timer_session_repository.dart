import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/command.dart';
import '../models/timer_session.dart';

class TimerSessionRepository {
  static const String _kTimerSessions = 'timer_sessions';

  final List<TimerSession> _sessions = [];

  List<TimerSession> get sessions => List.unmodifiable(_sessions);

  Future<Result<void>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kTimerSessions);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _sessions
          ..clear()
          ..addAll(
            list.map(
              (item) => TimerSession.fromJson(item as Map<String, dynamic>),
            ),
          );
      }
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> addSession(TimerSession session) async {
    try {
      _sessions.add(session);
      await _persist();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_sessions.map((session) => session.toJson()).toList());
    await prefs.setString(_kTimerSessions, json);
  }
}
