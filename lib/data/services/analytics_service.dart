import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'remote/analytics_firestore_service.dart';

/// Sends the app's analytics events to Firestore, so the data shows up in real time under `users/{uid}/analytics_events` and can be streamed from Firestore into BigQuery.
class AnalyticsService {
  factory AnalyticsService({
    AnalyticsFirestoreService? service,
    FirebaseAuth? auth,
  }) {
    if (service != null || auth != null) {
      return AnalyticsService._internal(service, auth);
    }
    return _instance ??= AnalyticsService._internal(null, null);
  }

  AnalyticsService._internal(
    AnalyticsFirestoreService? service,
    FirebaseAuth? auth,
  ) : _events = service ?? AnalyticsFirestoreService(),
      _customAuth = auth;

  static AnalyticsService? _instance;
  final AnalyticsFirestoreService _events;
  final FirebaseAuth? _customAuth;
  String? _userId;
  final Map<String, Object?> _userProperties = {};

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// The user the events belong to: the one set with [setUserId] if any, else the signed-in Firebase Auth user.
  String? get _currentUserId => _userId ?? _auth.currentUser?.uid;

  /// [NavigatorObserver] that logs a screen view whenever navigation changes.
  NavigatorObserver get observer => _AnalyticsNavigatorObserver(this);

  /// Writes an analytics event to Firestore with its parameters merged into the document, so each parameter can become its own BigQuery column.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Event: $name | params: $parameters');
    }
    final userId = _currentUserId;
    if (userId == null) {
      if (kDebugMode) {
        debugPrint('[Analytics] Skipped "$name": no user signed in');
      }
      return;
    }
    try {
      await _events.create(userId, {
        'name': name,
        'userId': userId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        ...?parameters,
        ..._userProperties,
      });
    } on Exception catch (error) {
      debugPrint('[Analytics] Failed to write event "$name": $error');
    }
  }

  /// Sets the user id the events belong to, so they are saved under that user's document even before Firebase Auth reports them.
  Future<void> setUserId(String? userId) async {
    _userId = userId;
  }

  /// Stores a user property that is added to every subsequent event.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    _userProperties[name] = value;
  }

  /// Logs a screen view event.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await logEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName, 'screen_class': ?screenClass},
    );
  }

  /// Logs the app_open event.
  Future<void> logAppOpen() async {
    await logEvent(name: 'app_open');
  }
}

/// Logs a screen view for the route the navigator lands on
class _AnalyticsNavigatorObserver extends NavigatorObserver {
  _AnalyticsNavigatorObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _logRoute(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _logRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _logRoute(previousRoute);
  }

  void _logRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name == '/') return;
    _analytics.logScreenView(screenName: name);
  }
}
