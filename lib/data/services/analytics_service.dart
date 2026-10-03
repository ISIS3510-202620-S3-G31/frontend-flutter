// Generated automatically by FirebaseAnalytics
// Google Analytics 4 2026-10-01 14:15:27

import 'package:firebase_analytics/firebase_analytics.dart';

/// Minimal service to manage Firebase Analytics throughout the app.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Exposes the underlying [FirebaseAnalytics] instance.
  FirebaseAnalytics get analytics => _analytics;

  /// [NavigatorObserver] to automatically log screen views when navigation changes.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs a custom analytics event with optional parameters.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Sets the user ID for analytics tracking.
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Sets a custom user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Manually logs a screen view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }
}
