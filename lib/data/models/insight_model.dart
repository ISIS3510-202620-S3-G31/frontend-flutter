enum InsightType {
  toolMoodCorrelation,
  moodTrend,
  timeOfDay,
  frequentEmotion,
  favoriteTool,
}

/// Where the insight button takes the user. The screen decides the route.
sealed class InsightAction {
  const InsightAction();
}

class OpenCheckIn extends InsightAction {
  const OpenCheckIn();
}

class OpenToolbox extends InsightAction {
  const OpenToolbox();
}

class OpenTool extends InsightAction {
  const OpenTool(this.toolId);

  final String toolId;
}

/// Something useful found in the user's own history, computed on the phone.
class Insight {
  const Insight({
    required this.type,
    required this.title,
    required this.message,
    required this.advice,
    required this.actionLabel,
    required this.action,
  });

  final InsightType type;
  final String title;
  final String message;
  final String advice;
  final String actionLabel;
  final InsightAction action;
}
