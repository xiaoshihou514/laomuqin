import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models/chat_message.dart';
import '../../data/models/task.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/services/alarm_service.dart';
import '../../utils/command.dart';

enum InputFlowState { idle, awaitingDeadline }

class MainViewModel extends ChangeNotifier {
  MainViewModel({
    required SettingsRepository settingsRepository,
    required TaskRepository taskRepository,
  })  : _settingsRepository = settingsRepository,
        _taskRepository = taskRepository {
    load = Command0(_load)..execute();
    submitTask = Command1<String, void>(_submitTask);
    confirmDeadline = Command1<(DateTime?, bool), void>(_confirmDeadline);
    startTask = Command1<String, void>(_startTask);
    askTasks = Command0(_askTasks);

    _asrSub = settingsRepository.asrStream.listen((enabled) {
      _asrEnabled = enabled;
      notifyListeners();
    });
    _asrModelSub = settingsRepository.asrModelStream.listen((json) {
      _asrModelSettingsJson = json;
      notifyListeners();
    });
  }

  final SettingsRepository _settingsRepository;
  final TaskRepository _taskRepository;

  late final StreamSubscription<bool> _asrSub;
  late final StreamSubscription<String?> _asrModelSub;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  InputFlowState _flowState = InputFlowState.idle;
  InputFlowState get flowState => _flowState;

  bool _asrEnabled = false;
  bool get asrEnabled => _asrEnabled;

  String? _asrModelSettingsJson;
  String? get asrModelSettingsJson => _asrModelSettingsJson;

  String? _pendingTaskTitle;

  late final Command0<void> load;
  late final Command1<String, void> submitTask;
  late final Command1<(DateTime?, bool), void> confirmDeadline;
  late final Command1<String, void> startTask;
  late final Command0<void> askTasks;

  @override
  void dispose() {
    _asrSub.cancel();
    _asrModelSub.cancel();
    super.dispose();
  }

  Future<Result<void>> _load() async {
    final asrResult = await _settingsRepository.isAsrEnabled();
    if (asrResult is Ok<bool>) {
      _asrEnabled = asrResult.value;
    }
    final modelResult = await _settingsRepository.getAsrModelSettings();
    if (modelResult is Ok<String?>) {
      _asrModelSettingsJson = modelResult.value;
    }
    await _taskRepository.loadTasks();
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
    _addMessage(ChatMessage(
      id: _newId(),
      type: ChatMessageType.timer,
      content: '',
      timestamp: DateTime.now(),
      taskId: title,
    ));
    notifyListeners();
    return Result.ok(null);
  }

  Future<Result<void>> _askTasks() async {
    final pending = _taskRepository.tasks
        .where((t) => t.status == TaskStatus.pending)
        .toList()
      ..sort((a, b) {
        if (a.terminationTime == null && b.terminationTime == null) return 0;
        if (a.terminationTime == null) return 1;
        if (b.terminationTime == null) return -1;
        return a.terminationTime!.compareTo(b.terminationTime!);
      });

    final String content;
    if (pending.isEmpty) {
      content = '🎉 暂无待办任务，休息一下吧！';
    } else {
      final fmt = DateFormat('MM/dd HH:mm');
      final lines = pending.take(10).map((t) {
        final deadline = t.terminationTime != null
            ? '  ⏰ ${fmt.format(t.terminationTime!)}'
            : '';
        return '• ${t.title}$deadline';
      });
      content = '📋 待办任务（${pending.length} 项）：\n${lines.join('\n')}';
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

  void resolveTimerStop(String taskId) {
    final idx = _messages.indexWhere(
      (m) => m.type == ChatMessageType.timer && m.taskId == taskId,
    );
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

  ChatMessage _makeUserMessage(String content) => ChatMessage(
        id: _newId(),
        type: ChatMessageType.user,
        content: content,
        timestamp: DateTime.now(),
      );

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

