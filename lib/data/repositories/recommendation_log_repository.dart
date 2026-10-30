import 'dart:async';
import 'dart:math';

import '../models/recommendation_model.dart';
import '../services/analytics_service.dart';

/// BQ3: writes down which tool the home recommended and whether the user opened it.
class RecommendationLogRepository {
  RecommendationLogRepository({AnalyticsService? analytics})
    : _analytics = analytics ?? AnalyticsService();

  final AnalyticsService _analytics;

  static const shownEvent = 'recommendation_shown';
  static const openedEvent = 'recommendation_opened';

  static const _idChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _random = Random();
  String logShown(Recommendation recommendation, {required String strategy}) {
    final id = _newId();
    unawaited(
      _analytics.logEvent(
        name: shownEvent,
        parameters: {
          'recommendation_id': id,
          'tool_id': recommendation.tool.id,
          'tool_name': recommendation.tool.title,
          'strategy': strategy,
          'reason': recommendation.reason,
          'emotion': ?recommendation.emotion?.name,
        },
      ),
    );
    return id;
  }

  void logOpened(String id, {required String toolId}) {
    unawaited(
      _analytics.logEvent(
        name: openedEvent,
        parameters: {'recommendation_id': id, 'tool_id': toolId},
      ),
    );
  }

  /// Twenty random letters and digits, like the ids Firestore makes.
  static String _newId() => String.fromCharCodes([
    for (var i = 0; i < 20; i++)
      _idChars.codeUnitAt(_random.nextInt(_idChars.length)),
  ]);
}
