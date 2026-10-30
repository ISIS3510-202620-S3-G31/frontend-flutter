/// One use of a toolbox activity, tracked from the moment the tool is opened until the user leaves it, so completed sessions can be told apart from abandoned ones (business question #9).
class ToolSessionRecord {
  const ToolSessionRecord({
    required this.toolId,
    required this.toolName,
    required this.startedAt,
    this.completed = false,
    this.completedAt,
    this.endedAt,
    this.durationSeconds,
    this.exitReason,
    this.lastStepName,
    this.lastStepAt,
  });

  final String toolId;
  final String toolName;

  final DateTime startedAt;

  final bool completed;

  final DateTime? completedAt;

  final DateTime? endedAt;

  final int? durationSeconds;

  final String? exitReason;

  final String? lastStepName;
  final DateTime? lastStepAt;

  Map<String, Object?> toMap() => {
    'toolId': toolId,
    'toolName': toolName,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completed': completed,
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'exitReason': exitReason,
    'lastStepName': lastStepName,
    'lastStepAt': lastStepAt?.toUtc().toIso8601String(),
  };

  static ToolSessionRecord fromMap(Map<String, Object?> map) =>
      ToolSessionRecord(
        toolId: map['toolId'] as String? ?? '',
        toolName: map['toolName'] as String? ?? '',
        startedAt:
            DateTime.tryParse(map['startedAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        completed: map['completed'] as bool? ?? false,
        completedAt: _date(map['completedAt']),
        endedAt: _date(map['endedAt']),
        durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
        exitReason: map['exitReason'] as String?,
        lastStepName: map['lastStepName'] as String?,
        lastStepAt: _date(map['lastStepAt']),
      );

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value as String)?.toLocal();
}
