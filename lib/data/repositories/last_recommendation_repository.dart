import 'dart:convert';

import '../models/check_in_model.dart';
import '../models/recommendation_model.dart';
import '../models/tool_model.dart';
import '../services/local/last_recommendation_storage.dart';


class LastRecommendationRepository {
  LastRecommendationRepository({LastRecommendationStorage? storage})
    : _storage = storage ?? LastRecommendationStorage();

  final LastRecommendationStorage _storage;

  static String _keyFor(String? userId) =>
      'last_recommendation_${userId ?? 'guest'}';


  Future<Recommendation?> load({
    required List<ToolItem> tools,
    String? userId,
  }) async {
    try {
      final saved = await _storage.read(_keyFor(userId));
      if (saved == null) return null;

      final json = jsonDecode(saved) as Map<String, dynamic>;
      final tool = tools.where((tool) => tool.id == json['toolId']).firstOrNull;
      if (tool == null) return null;

      return Recommendation(
        tool: tool,
        reason: json['reason'] as String,
        emotion: Emotion.values
            .where((emotion) => emotion.name == json['emotion'])
            .firstOrNull,
      );
    } catch (_) {
      return null;
    }
  }

  /// Replaces the saved recommendation with [recommendation].
  Future<void> save(Recommendation recommendation, {String? userId}) async {
    try {
      await _storage.write(
        _keyFor(userId),
        jsonEncode({
          'toolId': recommendation.tool.id,
          'reason': recommendation.reason,
          'emotion': ?recommendation.emotion?.name,
        }),
      );
    } catch (_) {
      // Not saving only means the next launch has no last recommendation.
    }
  }
}
