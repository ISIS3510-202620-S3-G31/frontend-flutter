import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/custom_breathing/custom_breathing_screen.dart';
import 'screens/emotional_detective/emotional_detective_screen.dart';
import 'screens/photo_of_the_day/photo_of_the_day_screen.dart';
import 'screens/scream_tank/scream_tank_screen.dart';
import 'screens/tear_collection/tear_collection_screen.dart';
import 'screens/tool_hub/tool_hub_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The screens are designed for portrait only.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const ToolHubScreen(),
    );
  }
}

/// Temporary entry point to open each screen until the app has real navigation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              FilledButton(
                onPressed: () => _open(context, const ToolHubScreen()),
                child: const Text('Your Toolbox'),
              ),
              FilledButton(
                onPressed: () => _open(context, const PhotoOfTheDayScreen()),
                child: const Text('Photo of the day'),
              ),
              FilledButton(
                onPressed: () => _open(context, const ScreamTankScreen()),
                child: const Text('Scream Tank'),
              ),
              FilledButton(
                onPressed: () => _open(context, const TearCollectionScreen()),
                child: const Text('Tear Collection'),
              ),
              FilledButton(
                onPressed: () => _open(context, const EmotionalDetectiveScreen()),
                child: const Text('Sprout Detective'),
              ),
              FilledButton(
                onPressed: () => _open(context, const CustomBreathingScreen()),
                child: const Text('Custom Breathing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}