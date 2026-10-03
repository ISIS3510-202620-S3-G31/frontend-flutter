import 'tool_model.dart';

/// The tool the home screen suggests and why it was picked.
class Recommendation {
  const Recommendation({required this.tool, required this.reason});

  final ToolItem tool;
  final String reason;
}
