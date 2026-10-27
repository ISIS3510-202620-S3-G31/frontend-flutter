import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/models/tool_session_model.dart';
import 'package:frontend_flutter/data/repositories/stats_repository.dart';

/// Answers with a fixed history, so the stats can be checked without Firebase.
class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository({this.checkIns = const [], this.sessions = const []});

  final List<CheckIn> checkIns;
  final List<ToolSession> sessions;

  DateTime? askedSince;

  @override
  Future<StatsData> dataSince(DateTime from) async {
    askedSince = from;
    return StatsData(checkIns: checkIns, sessions: sessions);
  }
}
