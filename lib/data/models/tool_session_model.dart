/// One time the user finished a tool.
class ToolSession {
  const ToolSession({
    required this.toolId,
    required this.startedAt,
    required this.durationSeconds,
  });

  /// Same id as in the tool catalog, for example "breathing".
  final String toolId;
  final DateTime startedAt;
  final int durationSeconds;
}
