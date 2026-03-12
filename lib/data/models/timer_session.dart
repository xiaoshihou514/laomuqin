class TimerSession {
  const TimerSession({
    required this.id,
    required this.taskId,
    required this.taskTitleSnapshot,
    required this.startedAt,
    required this.endedAt,
    required this.elapsedSeconds,
  });

  final String id;
  final String taskId;
  final String taskTitleSnapshot;
  final DateTime startedAt;
  final DateTime endedAt;
  final int elapsedSeconds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitleSnapshot': taskTitleSnapshot,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
      };

  factory TimerSession.fromJson(Map<String, dynamic> json) {
    return TimerSession(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskTitleSnapshot: json['taskTitleSnapshot'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      elapsedSeconds: json['elapsedSeconds'] as int,
    );
  }
}
