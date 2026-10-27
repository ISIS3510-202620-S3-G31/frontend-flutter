import '../models/recommendation_model.dart';
import '../services/auth_service.dart';
import '../services/remote/recommendation_firestore_service.dart';

/// Writes down which tool the app recommended and whether the user opened it.
class RecommendationLogRepository {
  RecommendationLogRepository({
    RecommendationFirestoreService? service,
    AuthService? auth,
  }) : _service = service ?? RecommendationFirestoreService(),
       _auth = auth ?? AuthService();

  final RecommendationFirestoreService _service;
  final AuthService _auth;

  /// Returns the id of the record, or null when nobody is signed in.
  String? logShown(
    Recommendation recommendation, {
    required String strategy,
    required DateTime shownAt,
  }) {
    final userId = _auth.currentUserId;
    if (userId == null) return null;
    return _service.add(userId, {
      'toolId': recommendation.tool.id,
      'toolName': recommendation.tool.title,
      'strategy': strategy,
      'reason': recommendation.reason,
      'shownAt': shownAt.toUtc().toIso8601String(),
      'opened': false,
    });
  }

  void logOpened(String id, DateTime openedAt) {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    _service.update(userId, id, {
      'opened': true,
      'openedAt': openedAt.toUtc().toIso8601String(),
    });
  }
}
