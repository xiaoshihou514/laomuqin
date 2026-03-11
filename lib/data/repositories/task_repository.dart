import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../../utils/command.dart';

class TaskRepository {
  static const String _kTasks = 'tasks';

  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  Future<Result<void>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kTasks);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(list.map(_fromJson));
      }
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> addTask(Task task) async {
    try {
      _tasks.add(task);
      await _persist();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> updateTask(Task task) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        await _persist();
      }
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> deleteTask(String id) async {
    try {
      _tasks.removeWhere((t) => t.id == id);
      await _persist();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_tasks.map(_toJson).toList());
    await prefs.setString(_kTasks, json);
  }

  Map<String, dynamic> _toJson(Task t) => {
        'id': t.id,
        'title': t.title,
        'terminationTime': t.terminationTime?.toIso8601String(),
        'status': t.status.name,
        'alarmId': t.alarmId,
      };

  Task _fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      terminationTime: map['terminationTime'] != null
          ? DateTime.parse(map['terminationTime'] as String)
          : null,
      status: TaskStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      alarmId: map['alarmId'] as int?,
    );
  }
}
