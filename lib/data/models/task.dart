enum TaskStatus { pending, inProgress, done }

class Task {
  const Task({
    required this.id,
    required this.title,
    this.terminationTime,
    this.status = TaskStatus.pending,
    this.alarmId,
  });

  final String id;
  final String title;
  final DateTime? terminationTime;
  final TaskStatus status;

  /// Local notification ID for the deadline alarm, if any.
  final int? alarmId;

  Task copyWith({
    String? id,
    String? title,
    DateTime? terminationTime,
    bool clearTerminationTime = false,
    TaskStatus? status,
    int? alarmId,
    bool clearAlarmId = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      terminationTime:
          clearTerminationTime ? null : terminationTime ?? this.terminationTime,
      status: status ?? this.status,
      alarmId: clearAlarmId ? null : alarmId ?? this.alarmId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
