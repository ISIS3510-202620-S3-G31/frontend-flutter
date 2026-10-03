import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/services/analytics_service.dart';
import 'firebase_options.dart';
import 'ui/auth/widgets/auth_gate.dart';
import 'ui/core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // The screens are designed for portrait only.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, this.analyticsService});

  final AnalyticsService? analyticsService;

  static final AnalyticsService _defaultAnalyticsService = AnalyticsService();

  @override
  Widget build(BuildContext context) {
    final analytics = analyticsService ?? _defaultAnalyticsService;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
      ),
      navigatorObservers: [analytics.observer],
      home: const AuthGate(),
    );
  }
}
