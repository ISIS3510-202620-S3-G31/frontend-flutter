import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/home/widgets/tool_hub_screen.dart';
import 'ui/core/theme/app_colors.dart';

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
