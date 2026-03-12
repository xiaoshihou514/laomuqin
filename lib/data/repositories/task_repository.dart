import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/command.dart';
import '../models/task.dart';

class TaskRepository {
  static const String _kTasks = 'tasks';

  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  Task? getTaskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<Result<void>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kTasks);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(list.map((item) => Task.fromJson(item as Map<String, dynamic>)));
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
    final json = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_kTasks, json);
  }
}
