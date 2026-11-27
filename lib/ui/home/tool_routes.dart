import 'package:flutter/material.dart';

import '../tools/breathing/widgets/custom_breathing_screen.dart';
import '../tools/cookie_jar/widgets/cookie_jar_screen.dart';
import '../tools/fortune/widgets/fortune_cookie_screen.dart';
import '../tools/photo/widgets/photo_of_the_day_screen.dart';
import '../tools/rapunzel/widgets/rapunzel_sky_screen.dart';
import '../tools/scream_tank/widgets/scream_tank_screen.dart';

/// Screen of each tool that is already built. Tools missing here are shown as
/// "coming soon".
const Map<String, WidgetBuilder> toolScreens = {
  'photo': _photoScreen,
  'breathing': _breathingScreen,
  'scream': _screamScreen,
  'fortune_cookie': _fortuneScreen,
  'rapunzel': _rapunzelScreen,
  'cookie_jar': _cookieJarScreen,
};

Widget _photoScreen(BuildContext context) => const PhotoOfTheDayScreen();
Widget _breathingScreen(BuildContext context) => const CustomBreathingScreen();
Widget _screamScreen(BuildContext context) => const ScreamTankScreen();
Widget _fortuneScreen(BuildContext context) => const FortuneCookieScreen();
Widget _rapunzelScreen(BuildContext context) => const RapunzelSkyScreen();
Widget _cookieJarScreen(BuildContext context) => const CookieJarScreen();
