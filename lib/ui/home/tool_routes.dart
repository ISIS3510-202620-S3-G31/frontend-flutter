import 'package:flutter/material.dart';

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

Widget _photoScreen(BuildContext context) => const PhotoOfTheDayScreen();
Widget _breathingScreen(BuildContext context) => const CustomBreathingScreen();
Widget _screamScreen(BuildContext context) => const ScreamTankScreen();
Widget _tearScreen(BuildContext context) => const TearCollectionScreen();
Widget _detectiveScreen(BuildContext context) =>
    const EmotionalDetectiveScreen();
