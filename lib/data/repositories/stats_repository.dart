import '../models/check_in_model.dart';
import '../models/tool_session_model.dart';
import '../services/local/sample_stats_service.dart';

class StatsRepository {
  StatsRepository({SampleStatsService? source})
    : _source = source ?? SampleStatsService();

  final SampleStatsService _source;

  Future<List<CheckIn>> checkInsSince(DateTime from) async => [
    for (final checkIn in await _source.checkIns())
      if (!checkIn.timestamp.isBefore(from)) checkIn,
  ];

  Future<List<ToolSession>> sessionsSince(DateTime from) async => [
    for (final session in await _source.toolSessions())
      if (!session.startedAt.isBefore(from)) session,
  ];
}
