import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/services/analytics_service.dart';
import 'firebase_options.dart';
import 'ui/auth/widgets/auth_gate.dart';
import 'ui/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AnalyticsService().logAppOpen();
  _reportErrors();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MainApp());
}

void _reportErrors() {
  final analytics = AnalyticsService();
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    analytics.logAppError(details.exception, details.stack, kind: 'flutter');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    analytics.logAppError(error, stack, kind: 'uncaught');
    return false;
  };
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
      theme: AppTheme.light,
      navigatorObservers: [analytics.observer],
      home: const AuthGate(),
    );
  }
}
