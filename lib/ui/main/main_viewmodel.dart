import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models/chat_message.dart';
import '../../data/models/task.dart';
import '../../data/models/timer_session.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/timer_session_repository.dart';
import '../../data/services/alarm_service.dart';
import '../../utils/command.dart';

enum InputFlowState { idle, awaitingDeadline }

class MainViewModel extends ChangeNotifier {
  MainViewModel({
    required TaskRepository taskRepository,
    required TimerSessionRepository timerSessionRepository,
    required SettingsRepository settingsRepository,
  })  : _taskRepository = taskRepository,
        _timerSessionRepository = timerSessionRepository,
        _settingsRepository = settingsRepository {
    load = Command0(_load)..execute();
    submitTask = Command1<String, void>(_submitTask);
    confirmDeadline = Command1<(DateTime?, bool), void>(_confirmDeadline);
    startTask = Command1<String, void>(_startTask);
    askTasks = Command0(_askTasks);
  }

  final TaskRepository _taskRepository;
  final TimerSessionRepository _timerSessionRepository;
  final SettingsRepository _settingsRepository;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  InputFlowState _flowState = InputFlowState.idle;
  InputFlowState get flowState => _flowState;

  String? _pendingTaskTitle;

  late final Command0<void> load;
  late final Command1<String, void> submitTask;
  late final Command1<(DateTime?, bool), void> confirmDeadline;
  late final Command1<String, void> startTask;
  late final Command0<void> askTasks;

  List<Task> get timerCandidates => _sortedPendingTasks();


  Future<Result<void>> _load() async {
    await _taskRepository.loadTasks();
    await _timerSessionRepository.loadSessions();
    _addMessage(ChatMessage(
      id: _newId(),
      type: ChatMessageType.system,
      content: '有什么我可以帮你的？',
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    return Result.ok(null);
  }

  Future<Result<void>> _submitTask(String title) async {
    _addMessage(_makeUserMessage(title));
    _pendingTaskTitle = title;
    _flowState = InputFlowState.awaitingDeadline;
    notifyListeners();
    return Result.ok(null);
  }

  Future<Result<void>> _confirmDeadline((DateTime?, bool) args) async {
    final (deadline, withAlarm) = args;
    final title = _pendingTaskTitle;
    if (title == null) return Result.ok(null);

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    int? alarmId;

    if (deadline != null && withAlarm) {
      alarmId = AlarmService.notificationIdFor(taskId);
      try {
        await AlarmService.scheduleTaskAlarm(
          notificationId: alarmId,
          taskTitle: title,
          deadline: deadline,
        );
      } catch (_) {
        // Alarm scheduling failure is non-fatal.
        alarmId = null;
      }
    }

    final task = Task(
      id: taskId,
      title: title,
      terminationTime: deadline,
      alarmId: alarmId,
    );
    await _taskRepository.addTask(task);

    _pendingTaskTitle = null;
    _flowState = InputFlowState.idle;
    notifyListeners();
    return Result.ok(null);
  }

  Future<Result<void>> _startTask(String title) async {
    final task = _taskRepository.getTaskById(title);
    if (task == null) {
      return Result.ok(null);
    }
    _addMessage(ChatMessage(
      id: _newId(),
      type: ChatMessageType.timer,
      content: task.title,
      timestamp: DateTime.now(),
      taskId: task.id,
    ));
    notifyListeners();
    return Result.ok(null);
  }

  Future<Result<void>> _askTasks() async {
    final pending = _sortedPendingTasks();

    final String content;
    if (pending.isEmpty) {
      content = '🎉 暂无待办任务，休息一下吧！';
    } else {
      final currentSignature = _recommendationSignature(pending);
      var nextIndex = 0;

      final storedSignatureResult =
          await _settingsRepository.getRecommendationSignature();
      final storedIndexResult = await _settingsRepository.getRecommendationIndex();
      String? storedSignature;
      int? storedIndex;

      if (storedSignatureResult case Ok<String?>(:final value)) {
        storedSignature = value;
      }
      if (storedIndexResult case Ok<int>(:final value)) {
        storedIndex = value;
      }

      if (storedSignature == currentSignature) {
        nextIndex = storedIndex ?? 0;
      }

      if (nextIndex >= pending.length) {
        nextIndex = 0;
      }

      final task = pending[nextIndex];
      final deadline = task.terminationTime != null
          ? '（截止 ${DateFormat('MM/dd HH:mm').format(task.terminationTime!)}）'
          : '（无截止时间）';
      content = '建议先做：${task.title}$deadline';

      await _settingsRepository.setRecommendationSignature(currentSignature);
      await _settingsRepository.setRecommendationIndex(
        (nextIndex + 1) % pending.length,
      );
    }

    _addMessage(ChatMessage(
      id: _newId(),
      type: ChatMessageType.system,
      content: content,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
    return Result.ok(null);
  }

  Future<void> resolveTimerStop(
    String taskId,
    Duration elapsed,
    DateTime startedAt,
    DateTime endedAt,
  ) async {
    final idx = _messages.indexWhere(
      (m) => m.type == ChatMessageType.timer && m.taskId == taskId,
    );
    final task = _taskRepository.getTaskById(taskId);
    if (task != null) {
      final session = TimerSession(
        id: _newId(),
        taskId: task.id,
        taskTitleSnapshot: task.title,
        startedAt: startedAt,
        endedAt: endedAt,
        elapsedSeconds: elapsed.inSeconds,
      );
      await _timerSessionRepository.addSession(session);
      await _taskRepository.updateTask(
        task.copyWith(trackedSeconds: task.trackedSeconds + elapsed.inSeconds),
      );
    }
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        content: '任务已结束',
        clearInlineWidget: true,
      );
      notifyListeners();
    }
  }

  void addDeadlinePromptWidget(Widget widget, String messageId) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(inlineWidget: widget);
      notifyListeners();
    }
  }

  void removeInlineWidget(String messageId) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(clearInlineWidget: true);
      notifyListeners();
    }
  }

  /// Returns the id of the newly added deadline prompt message.
  String addDeadlinePrompt(String promptText) {
    final msg = ChatMessage(
      id: _newId(),
      type: ChatMessageType.system,
      content: promptText,
      timestamp: DateTime.now(),
    );
    _addMessage(msg);
    notifyListeners();
    return msg.id;
  }

  void addConfirmationMessage(String text) {
    _addMessage(ChatMessage(
      id: _newId(),
      type: ChatMessageType.system,
      content: text,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void _addMessage(ChatMessage msg) {
    _messages.add(msg);
  }

  List<Task> _sortedPendingTasks() {
    final indexed = _taskRepository.tasks
        .asMap()
        .entries
        .where((entry) => entry.value.status == TaskStatus.pending)
        .toList();

    indexed.sort((a, b) {
      final left = a.value;
      final right = b.value;
      if (left.terminationTime == null && right.terminationTime == null) {
        return a.key.compareTo(b.key);
      }
      if (left.terminationTime == null) return 1;
      if (right.terminationTime == null) return -1;
      final deadlineCompare =
          left.terminationTime!.compareTo(right.terminationTime!);
      if (deadlineCompare != 0) return deadlineCompare;
      return a.key.compareTo(b.key);
    });

    return indexed.map((entry) => entry.value).toList();
  }

  String _recommendationSignature(List<Task> tasks) {
    return tasks
        .map(
          (task) =>
              '${task.id}:${task.terminationTime?.millisecondsSinceEpoch ?? 'none'}:${task.status.name}',
        )
        .join('|');
  }

  ChatMessage _makeUserMessage(String content) => ChatMessage(
        id: _newId(),
        type: ChatMessageType.user,
        content: content,
        timestamp: DateTime.now(),
      );

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
