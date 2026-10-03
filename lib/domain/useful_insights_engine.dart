import '../data/models/check_in_model.dart';
import '../data/models/insight_model.dart';
import '../data/models/tool_session_model.dart';

/// Looks at the user's check-ins and tool sessions on the phone and returns
/// what is worth telling them, most useful first.
///
/// Same rules and thresholds as the Kotlin app, so both say the same thing.
/// Each rule returns null when there is not enough data to be sure.
class UsefulInsightsEngine {
  UsefulInsightsEngine({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const _longWindowDays = 30;
  static const _minDaysEachSide = 2;
  static const _minReduction = 0.2;
  static const _minCheckInsPerWeek = 2;
  static const _minTrendChange = 0.2;
  static const _minDifficultCheckIns = 4;
  static const _minTimeOfDayShare = 0.6;
  static const _minCheckInsForEmotion = 3;
  static const _minEmotionShare = 0.5;
  static const _minSessions = 3;
  static const _minUses = 2;

  List<Insight> generate({
    required List<CheckIn> checkIns,
    required List<ToolSession> sessions,
    required Map<String, String> toolNames,
  }) {
    final today = _dayNumber(_now());
    return [
      ?_toolMoodCorrelation(checkIns, sessions, today, toolNames),
      ?_moodTrend(checkIns, today),
      ?_timeOfDayPattern(checkIns, today),
      ?_frequentEmotion(checkIns, today),
      ?_favoriteTool(sessions, today, toolNames),
    ];
  }

  /// Compares how hard the days were with and without each tool.
  Insight? _toolMoodCorrelation(
    List<CheckIn> checkIns,
    List<ToolSession> sessions,
    int today,
    Map<String, String> toolNames,
  ) {
    final distressByDay = <int, List<double>>{};
    for (final checkIn in checkIns) {
      final day = _dayNumber(checkIn.timestamp);
      if (!_inWindow(today - day, 0, _longWindowDays)) continue;
      final distress = checkIn.isDifficult ? checkIn.intensity.toDouble() : 0.0;
      distressByDay.putIfAbsent(day, () => []).add(distress);
    }
    if (distressByDay.isEmpty) return null;
    final averageByDay = {
      for (final entry in distressByDay.entries)
        entry.key: _average(entry.value),
    };

    final daysByTool = <String, Set<int>>{};
    for (final session in sessions) {
      final day = _dayNumber(session.startedAt);
      if (!_inWindow(today - day, 0, _longWindowDays)) continue;
      daysByTool.putIfAbsent(session.toolId, () => {}).add(day);
    }

    String? bestToolId;
    var bestReduction = 0.0;
    for (final entry in daysByTool.entries) {
      final withTool = [
        for (final day in averageByDay.keys)
          if (entry.value.contains(day)) averageByDay[day]!,
      ];
      final withoutTool = [
        for (final day in averageByDay.keys)
          if (!entry.value.contains(day)) averageByDay[day]!,
      ];
      if (withTool.length < _minDaysEachSide ||
          withoutTool.length < _minDaysEachSide) {
        continue;
      }
      final averageWithout = _average(withoutTool);
      if (averageWithout <= 0) continue;
      final reduction = (averageWithout - _average(withTool)) / averageWithout;
      if (reduction >= _minReduction && reduction > bestReduction) {
        bestToolId = entry.key;
        bestReduction = reduction;
      }
    }

    if (bestToolId == null) return null;
    final name = _toolName(bestToolId, toolNames);
    return Insight(
      type: InsightType.toolMoodCorrelation,
      title: '$name helps you',
      message:
          'On days you used $name, your difficult feelings were '
          '${_percent(bestReduction)}% lower than on other days.',
      advice: 'Keep $name close for tough days.',
      actionLabel: 'Open $name',
      action: OpenTool(bestToolId),
    );
  }

  /// Compares the share of difficult check-ins this week against last week.
  Insight? _moodTrend(List<CheckIn> checkIns, int today) {
    final thisWeek = [
      for (final c in checkIns)
        if (_inWindow(today - _dayNumber(c.timestamp), 0, 7)) c,
    ];
    final lastWeek = [
      for (final c in checkIns)
        if (_inWindow(today - _dayNumber(c.timestamp), 7, 14)) c,
    ];
    if (thisWeek.length < _minCheckInsPerWeek ||
        lastWeek.length < _minCheckInsPerWeek) {
      return null;
    }

    final shareNow = _difficultShare(thisWeek);
    final shareBefore = _difficultShare(lastWeek);
    final change = shareNow - shareBefore;
    if (change.abs() < _minTrendChange) return null;

    if (change < 0) {
      return Insight(
        type: InsightType.moodTrend,
        title: 'A lighter week',
        message:
            '${_percent(shareNow)}% of your check-ins this week were '
            'difficult, down from ${_percent(shareBefore)}% last week.',
        advice: 'Whatever you are doing is working. Keep checking in.',
        actionLabel: 'Check in',
        action: const OpenCheckIn(),
      );
    }
    return Insight(
      type: InsightType.moodTrend,
      title: 'A heavier week',
      message:
          '${_percent(shareNow)}% of your check-ins this week were '
          'difficult, up from ${_percent(shareBefore)}% last week.',
      advice: 'Be gentle with yourself. A calming tool can help.',
      actionLabel: 'Find a tool',
      action: const OpenToolbox(),
    );
  }

  /// Checks whether difficult check-ins pile up at one time of the day.
  Insight? _timeOfDayPattern(List<CheckIn> checkIns, int today) {
    final difficult = [
      for (final c in checkIns)
        if (c.isDifficult &&
            _inWindow(today - _dayNumber(c.timestamp), 0, _longWindowDays))
          c,
    ];
    if (difficult.length < _minDifficultCheckIns) return null;

    final counts = <_DayPart, int>{};
    for (final checkIn in difficult) {
      final part = _DayPart.of(checkIn.timestamp.hour);
      counts[part] = (counts[part] ?? 0) + 1;
    }
    // Most check-ins first; on a tie, the earlier part of the day wins.
    final top = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
      });
    final best = top.first;
    if (best.value / difficult.length < _minTimeOfDayShare) return null;

    final part = best.key.label;
    return Insight(
      type: InsightType.timeOfDay,
      title: 'Tough moments come $part',
      message:
          '${best.value} of your last ${difficult.length} difficult '
          'check-ins happened $part.',
      advice: 'Try a calming tool $part, before the feeling builds up.',
      actionLabel: 'Find a tool',
      action: const OpenToolbox(),
    );
  }

  /// The emotion that showed up most in this week's check-ins.
  Insight? _frequentEmotion(List<CheckIn> checkIns, int today) {
    final thisWeek = [
      for (final c in checkIns)
        if (_inWindow(today - _dayNumber(c.timestamp), 0, 7)) c,
    ];
    if (thisWeek.length < _minCheckInsForEmotion) return null;

    // Each emotion counts once per check-in.
    final counts = <Emotion, int>{};
    for (final checkIn in thisWeek) {
      for (final emotion in checkIn.emotions.toSet()) {
        counts[emotion] = (counts[emotion] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    // Most frequent first; on a tie, the first one in the enum wins.
    final top = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.index.compareTo(b.key.index);
      });
    final best = top.first;
    if (best.value / thisWeek.length < _minEmotionShare) return null;

    final name = best.key.label;
    final message =
        '$name showed up in ${best.value} of your ${thisWeek.length} '
        'check-ins this week.';
    if (best.key.isDifficult) {
      return Insight(
        type: InsightType.frequentEmotion,
        title: '$name has been around',
        message: message,
        advice:
            'Naming a feeling is the first step. A Release or Calm down '
            'tool can help with it.',
        actionLabel: 'Find a tool',
        action: const OpenToolbox(),
      );
    }
    return Insight(
      type: InsightType.frequentEmotion,
      title: '$name has been around',
      message: message,
      advice:
          'Notice what made those moments good and keep making room for it.',
      actionLabel: 'Check in',
      action: const OpenCheckIn(),
    );
  }

  /// The tool used most in the last month.
  Insight? _favoriteTool(
    List<ToolSession> sessions,
    int today,
    Map<String, String> toolNames,
  ) {
    final recent = [
      for (final s in sessions)
        if (_inWindow(today - _dayNumber(s.startedAt), 0, _longWindowDays)) s,
    ];
    if (recent.length < _minSessions) return null;

    final uses = <String, int>{};
    final lastUse = <String, DateTime>{};
    for (final session in recent) {
      uses[session.toolId] = (uses[session.toolId] ?? 0) + 1;
      final last = lastUse[session.toolId];
      if (last == null || session.startedAt.isAfter(last)) {
        lastUse[session.toolId] = session.startedAt;
      }
    }
    // Most used first; on a tie, the one used most recently wins.
    final ranking = uses.keys.toList()
      ..sort((a, b) {
        final byUses = uses[b]!.compareTo(uses[a]!);
        return byUses != 0 ? byUses : lastUse[b]!.compareTo(lastUse[a]!);
      });
    final toolId = ranking.first;
    if (uses[toolId]! < _minUses) return null;

    final name = _toolName(toolId, toolNames);
    return Insight(
      type: InsightType.favoriteTool,
      title: 'Your go-to tool',
      message:
          'You used $name ${uses[toolId]} times in the last '
          '$_longWindowDays days, more than any other tool.',
      advice:
          'Tools you trust work best when you start them early, before a '
          'feeling peaks.',
      actionLabel: 'Open $name',
      action: OpenTool(toolId),
    );
  }

  /// Same number for two moments of the same local day.
  static int _dayNumber(DateTime time) =>
      DateTime.utc(time.year, time.month, time.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static bool _inWindow(int daysAgo, int from, int until) =>
      daysAgo >= from && daysAgo < until;

  static double _average(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static double _difficultShare(List<CheckIn> checkIns) =>
      checkIns.where((c) => c.isDifficult).length / checkIns.length;

  static String _toolName(String toolId, Map<String, String> toolNames) =>
      toolNames[toolId] ?? toolId;

  static int _percent(double value) => (value * 100).round();
}

enum _DayPart {
  night('at night', 0, 5),
  morning('in the morning', 5, 12),
  afternoon('in the afternoon', 12, 18),
  evening('in the evening', 18, 24);

  const _DayPart(this.label, this.from, this.until);

  final String label;
  final int from;
  final int until;

  static _DayPart of(int hour) =>
      values.firstWhere((part) => hour >= part.from && hour < part.until);
}
