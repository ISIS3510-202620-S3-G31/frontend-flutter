import 'package:flutter/foundation.dart';

import '../../../data/models/check_in_model.dart';
import '../../../data/models/insight_model.dart';
import '../../../data/models/tool_session_model.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/tool_repository.dart';
import '../../../domain/useful_insights_engine.dart';

/// Dominant emotion of one day and its average intensity (1 to 5).
class DayMood {
  const DayMood({required this.emotion, required this.intensity});

  final Emotion emotion;
  final double intensity;
}

/// Part of all tool sessions that went to one tool.
class ToolShare {
  const ToolShare({required this.name, required this.percent});

  final String name;
  final int percent;
}

class StatsViewModel extends ChangeNotifier {
  StatsViewModel({
    StatsRepository? repository,
    ToolRepository? toolRepository,
    DateTime Function()? now,
  }) : _repository = repository ?? StatsRepository(),
       _toolRepository = toolRepository ?? const ToolRepository(),
       _now = now ?? DateTime.now,
       _insightsEngine = UsefulInsightsEngine(now: now);

  static const _maxToolsShown = 4;
  static const _maxInsightsShown = 3;

  final StatsRepository _repository;
  final ToolRepository _toolRepository;
  final DateTime Function() _now;
  final UsefulInsightsEngine _insightsEngine;

  bool _loading = true;
  bool _isSample = true;
  bool _disposed = false;
  Emotion? _topFeeling;
  int _weekCheckIns = 0;
  List<DayMood?> _week = List.filled(7, null);
  List<ToolShare> _toolShares = [];
  List<Insight> _insights = [];

  bool get loading => _loading;

  /// True while these numbers are the sample history, not the user's own.
  bool get isSample => _isSample;

  /// Title of a tool, to show it the same way the toolbox does.
  String toolNameOf(String toolId) {
    for (final tool in _toolRepository.allTools()) {
      if (tool.id == toolId) return tool.title;
    }
    return toolId;
  }

  /// Most frequent emotion in this week's check-ins, or null if there are none.
  Emotion? get topFeeling => _topFeeling;
  int get weekCheckIns => _weekCheckIns;

  /// Monday to Sunday of this week; null on days without a check-in.
  List<DayMood?> get week => _week;
  List<ToolShare> get toolShares => _toolShares;
  List<Insight> get insights => _insights;

  Future<void> load() async {
    _loading = true;
    _notify();
    try {
      await _load();
    } finally {
      // Whatever happens, the screen must stop waiting.
      _loading = false;
      _notify();
    }
  }

  Future<void> _load() async {
    final now = _now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final monthAgo = DateTime(now.year, now.month, now.day - 29);

    final data = await _repository.dataSince(monthAgo);
    final checkIns = data.checkIns;
    final sessions = data.sessions;
    _isSample = data.isSample;
    final toolNames = {
      for (final tool in _toolRepository.allTools()) tool.id: tool.title,
    };

    final thisWeek = [
      for (final checkIn in checkIns)
        if (!checkIn.timestamp.isBefore(monday)) checkIn,
    ];
    _weekCheckIns = thisWeek.length;
    _topFeeling = _mostFrequentEmotion(thisWeek);
    _week = [
      for (var i = 0; i < 7; i++)
        _moodOf(thisWeek, DateTime(monday.year, monday.month, monday.day + i)),
    ];
    _toolShares = _sharesOf(sessions, toolNames);
    _insights = _insightsEngine
        .generate(checkIns: checkIns, sessions: sessions, toolNames: toolNames)
        .take(_maxInsightsShown)
        .toList();
  }

  DayMood? _moodOf(List<CheckIn> checkIns, DateTime day) {
    final sameDay = [
      for (final checkIn in checkIns)
        if (checkIn.timestamp.year == day.year &&
            checkIn.timestamp.month == day.month &&
            checkIn.timestamp.day == day.day)
          checkIn,
    ];
    final emotion = _mostFrequentEmotion(sameDay);
    if (emotion == null) return null;
    final total = sameDay.fold(0, (sum, checkIn) => sum + checkIn.intensity);
    return DayMood(emotion: emotion, intensity: total / sameDay.length);
  }

  /// On a tie, the first emotion of the enum wins, so the result is stable.
  Emotion? _mostFrequentEmotion(List<CheckIn> checkIns) {
    final counts = <Emotion, int>{};
    for (final checkIn in checkIns) {
      for (final emotion in checkIn.emotions.toSet()) {
        counts[emotion] = (counts[emotion] ?? 0) + 1;
      }
    }
    Emotion? best;
    for (final emotion in Emotion.values) {
      final count = counts[emotion] ?? 0;
      if (count > 0 && (best == null || count > counts[best]!)) best = emotion;
    }
    return best;
  }

  /// The most used tools; when there are more than fit, the rest are grouped.
  List<ToolShare> _sharesOf(
    List<ToolSession> sessions,
    Map<String, String> toolNames,
  ) {
    if (sessions.isEmpty) return [];
    final uses = <String, int>{};
    for (final session in sessions) {
      uses[session.toolId] = (uses[session.toolId] ?? 0) + 1;
    }
    final ranking = uses.keys.toList()
      ..sort((a, b) => uses[b]!.compareTo(uses[a]!));

    final names = <String>[];
    final counts = <int>[];
    for (final toolId in ranking.take(_maxToolsShown - 1)) {
      names.add(toolNames[toolId] ?? toolId);
      counts.add(uses[toolId]!);
    }
    final rest = ranking.skip(_maxToolsShown - 1).toList();
    if (rest.length == 1) {
      names.add(toolNames[rest.first] ?? rest.first);
      counts.add(uses[rest.first]!);
    } else if (rest.length > 1) {
      names.add('Other tools');
      counts.add(rest.fold(0, (sum, toolId) => sum + uses[toolId]!));
    }

    final percents = _roundedPercents(counts);
    return [
      for (var i = 0; i < names.length; i++)
        ToolShare(name: names[i], percent: percents[i]),
    ];
  }

  /// Rounds each part so that together they still add up to exactly 100.
  static List<int> _roundedPercents(List<int> counts) {
    final total = counts.fold<int>(0, (sum, count) => sum + count);
    final exact = [for (final count in counts) count * 100 / total];
    final rounded = [for (final value in exact) value.floor()];
    final missing = 100 - rounded.fold<int>(0, (sum, value) => sum + value);
    final byRemainder = List.generate(
      counts.length,
      (i) => i,
    )..sort((a, b) => (exact[b] - rounded[b]).compareTo(exact[a] - rounded[a]));
    for (final i in byRemainder.take(missing)) {
      rounded[i]++;
    }
    return rounded;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
