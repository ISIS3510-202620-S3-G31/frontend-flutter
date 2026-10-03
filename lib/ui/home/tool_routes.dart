import 'package:flutter/material.dart';

import '../../data/services/analytics_service.dart';
import '../feedback/widgets/tool_feedback_screen.dart';
import '../tools/breathing/widgets/custom_breathing_screen.dart';
import '../tools/emotional_detective/widgets/emotional_detective_screen.dart';
import '../tools/photo/widgets/photo_of_the_day_screen.dart';
import '../tools/scream_tank/widgets/scream_tank_screen.dart';
import '../tools/tear_collection/widgets/tear_collection_screen.dart';

/// Screen of each tool that is already built. Tools missing here are shown as
/// "coming soon".
const Map<String, WidgetBuilder> toolScreens = {
  'photo': _photoScreen,
  'breathing': _breathingScreen,
  'scream': _screamScreen,
  'tear': _tearScreen,
  'detective': _detectiveScreen,
};

/// Leaving a tool sooner than this is a misclick, not a session worth rating.
const _minSecondsForFeedback = 10;

/// Opens a tool and, once the user comes back from it, asks how it went.
Future<void> openToolScreen(
  BuildContext context, {
  required String toolId,
  required String toolName,
  required WidgetBuilder builder,
  AnalyticsService? analyticsService,
}) async {
  final analytics = analyticsService ?? AnalyticsService();
  final startedAt = DateTime.now();
  await analytics.startToolSession(toolId: toolId, toolName: toolName);
  if (!context.mounted) return;

  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: builder,
      settings: RouteSettings(name: '/tools/$toolId'),
    ),
  );

  final seconds = DateTime.now().difference(startedAt).inSeconds;

  if (result == true) {
    await analytics.completeToolSession(
      toolId: toolId,
      toolName: toolName,
      durationSeconds: seconds,
    );
  }

  await analytics.endToolSession(
    toolId: toolId,
    toolName: toolName,
    durationSeconds: seconds,
  );

  if (!context.mounted || seconds < _minSecondsForFeedback) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ToolFeedbackScreen(
        toolId: toolId,
        toolName: toolName,
        startedAt: startedAt,
        durationSeconds: seconds,
      ),
    ),
  );
}

Widget _photoScreen(BuildContext context) => const PhotoOfTheDayScreen();
Widget _breathingScreen(BuildContext context) => const CustomBreathingScreen();
Widget _screamScreen(BuildContext context) => const ScreamTankScreen();
Widget _tearScreen(BuildContext context) => const TearCollectionScreen();
Widget _detectiveScreen(BuildContext context) =>
    const EmotionalDetectiveScreen();
