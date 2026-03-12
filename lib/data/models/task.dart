enum TaskStatus { pending, inProgress, done }

class Task {
  const Task({
    required this.id,
    required this.title,
    this.terminationTime,
    this.status = TaskStatus.pending,
    this.alarmId,
    this.trackedSeconds = 0,
  });

  final String id;
  final String title;
  final DateTime? terminationTime;
  final TaskStatus status;

  /// Local notification ID for the deadline alarm, if any.
  final int? alarmId;
  final int trackedSeconds;

  Task copyWith({
    String? id,
    String? title,
    DateTime? terminationTime,
    bool clearTerminationTime = false,
    TaskStatus? status,
    int? alarmId,
    bool clearAlarmId = false,
    int? trackedSeconds,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      terminationTime:
          clearTerminationTime ? null : terminationTime ?? this.terminationTime,
      status: status ?? this.status,
      alarmId: clearAlarmId ? null : alarmId ?? this.alarmId,
      trackedSeconds: trackedSeconds ?? this.trackedSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'terminationTime': terminationTime?.toIso8601String(),
        'status': status.name,
        'alarmId': alarmId,
        'trackedSeconds': trackedSeconds,
      };

  factory Task.fromJson(Map<String, dynamic> map) {
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
      trackedSeconds: map['trackedSeconds'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
